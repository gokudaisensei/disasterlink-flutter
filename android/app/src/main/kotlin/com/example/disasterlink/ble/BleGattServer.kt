package com.example.disasterlink.ble

import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*
import java.util.concurrent.ConcurrentHashMap

/**
 * BLE GATT Server implementation for DisasterLink P2P messaging
 *
 * This class implements a BLE GATT server that can:
 * - Advertise as a DisasterLink emergency device
 * - Accept connections from BLE centrals
 * - Handle message fragment reading/writing
 * - Notify connected devices of new messages
 */
class BleGattServer(private val context: Context) : MethodCallHandler {

    companion object {
        private const val TAG = "BleGattServer"

        // Service and Characteristic UUIDs (matching Dart constants)
        private val SERVICE_UUID = UUID.fromString("b32b86a1-a04c-4db3-8276-b17ec127dab1")
        private val WRITE_CHARACTERISTIC_UUID =
                UUID.fromString("25c54c03-9f43-4015-ba94-c923cbfd7a4b")
        private val NOTIFY_CHARACTERISTIC_UUID =
                UUID.fromString("c7911626-4838-4781-aae8-a5e6ea601ed2")
        private val READ_CHARACTERISTIC_UUID =
                UUID.fromString("d10fe796-9f87-43ab-ba06-00530ebee963")

        // BLE Constants
        private const val MAX_FRAGMENT_SIZE = 512
        private const val FRAGMENT_HEADER_SIZE = 12
        private const val FRAGMENT_PAYLOAD_SIZE = MAX_FRAGMENT_SIZE - FRAGMENT_HEADER_SIZE

        // Method Channel
        const val CHANNEL_NAME = "disasterlink/ble_peripheral"
    }

    private var bluetoothManager: BluetoothManager? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var gattServer: BluetoothGattServer? = null
    private var advertiser: BluetoothLeAdvertiser? = null
    private var methodChannel: MethodChannel? = null

    // Connected devices
    private val connectedDevices = ConcurrentHashMap<String, BluetoothDevice>()

    // Message fragment buffers
    private val fragmentBuffers = ConcurrentHashMap<String, MutableList<MessageFragment?>>()
    private val fragmentTimestamps = ConcurrentHashMap<String, Long>()

    // Current complete message for reading
    private var currentMessage: ByteArray? = null

    // Handler for main thread operations
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Initialize the BLE GATT server */
    fun initialize(channel: MethodChannel) {
        methodChannel = channel

        bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter

        if (bluetoothAdapter == null) {
            Log.e(TAG, "Bluetooth adapter not available")
            return
        }

        if (!context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            Log.e(TAG, "BLE not supported on this device")
            return
        }

        Log.d(TAG, "BLE GATT Server initialized")
    }

    /** Start the GATT server and begin advertising */
    private fun startServer(): Boolean {
        try {
            // Create GATT server
            gattServer = bluetoothManager?.openGattServer(context, gattServerCallback)
            if (gattServer == null) {
                Log.e(TAG, "Failed to create GATT server")
                return false
            }

            // Add DisasterLink service
            val service = createDisasterLinkService()
            if (!gattServer!!.addService(service)) {
                Log.e(TAG, "Failed to add DisasterLink service")
                return false
            }

            // Start advertising
            return startAdvertising()
        } catch (e: Exception) {
            Log.e(TAG, "Error starting GATT server", e)
            return false
        }
    }

    /** Stop the GATT server and advertising */
    private fun stopServer() {
        try {
            stopAdvertising()

            gattServer?.let { server ->
                server.clearServices()
                server.close()
            }
            gattServer = null

            connectedDevices.clear()
            fragmentBuffers.clear()
            fragmentTimestamps.clear()

            Log.d(TAG, "GATT server stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping GATT server", e)
        }
    }

    /** Create the DisasterLink BLE service with characteristics */
    private fun createDisasterLinkService(): BluetoothGattService {
        val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)

        // Write characteristic - for receiving message fragments
        val writeCharacteristic =
                BluetoothGattCharacteristic(
                        WRITE_CHARACTERISTIC_UUID,
                        BluetoothGattCharacteristic.PROPERTY_WRITE or
                                BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE,
                        BluetoothGattCharacteristic.PERMISSION_WRITE
                )

        // Notify characteristic - for sending message fragments
        val notifyCharacteristic =
                BluetoothGattCharacteristic(
                        NOTIFY_CHARACTERISTIC_UUID,
                        BluetoothGattCharacteristic.PROPERTY_NOTIFY or
                                BluetoothGattCharacteristic.PROPERTY_READ,
                        BluetoothGattCharacteristic.PERMISSION_READ
                )

        // Add notification descriptor
        val notifyDescriptor =
                BluetoothGattDescriptor(
                        UUID.fromString("00002902-0000-1000-8000-00805f9b34fb"),
                        BluetoothGattDescriptor.PERMISSION_WRITE or
                                BluetoothGattDescriptor.PERMISSION_READ
                )
        notifyCharacteristic.addDescriptor(notifyDescriptor)

        // Read characteristic - for reading the latest complete message
        val readCharacteristic =
                BluetoothGattCharacteristic(
                        READ_CHARACTERISTIC_UUID,
                        BluetoothGattCharacteristic.PROPERTY_READ,
                        BluetoothGattCharacteristic.PERMISSION_READ
                )

        service.addCharacteristic(writeCharacteristic)
        service.addCharacteristic(notifyCharacteristic)
        service.addCharacteristic(readCharacteristic)

        return service
    }

    /** Start BLE advertising */
    private fun startAdvertising(): Boolean {
        advertiser = bluetoothAdapter?.bluetoothLeAdvertiser
        if (advertiser == null) {
            Log.e(TAG, "Advertiser not available")
            return false
        }

        val settings =
                AdvertiseSettings.Builder()
                        .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_POWER)
                        .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
                        .setConnectable(true)
                        .setTimeout(0)
                        .build()

        // Minimal advertising data: only the service UUID
        val advertiseData = AdvertiseData.Builder().addServiceUuid(ParcelUuid(SERVICE_UUID)).build()

        // Additional scan response data: device name and TX power level
        val scanResponseData =
                AdvertiseData.Builder()
                        .setIncludeDeviceName(true)
                        .setIncludeTxPowerLevel(true)
                        .build()

        advertiser?.startAdvertising(settings, advertiseData, scanResponseData, advertiseCallback)
        return true
    }

    /** Stop BLE advertising */
    private fun stopAdvertising() {
        advertiser?.stopAdvertising(advertiseCallback)
    }

    /** Send a message to all connected devices */
    private fun sendMessage(messageBytes: ByteArray) {
        if (connectedDevices.isEmpty()) {
            Log.w(TAG, "No connected devices to send message to")
            return
        }

        val fragments = createFragments(messageBytes)

        for (device in connectedDevices.values) {
            for (fragment in fragments) {
                sendFragment(device, fragment)
            }
        }
    }

    /** Send a single fragment to a device */
    private fun sendFragment(device: BluetoothDevice, fragment: ByteArray) {
        val service = gattServer?.getService(SERVICE_UUID)
        val characteristic = service?.getCharacteristic(NOTIFY_CHARACTERISTIC_UUID)

        if (characteristic != null) {
            characteristic.value = fragment
            gattServer?.notifyCharacteristicChanged(device, characteristic, false)
        }
    }

    /** Create message fragments from a complete message */
    private fun createFragments(messageBytes: ByteArray): List<ByteArray> {
        val fragments = mutableListOf<ByteArray>()
        val totalFragments = (messageBytes.size + FRAGMENT_PAYLOAD_SIZE - 1) / FRAGMENT_PAYLOAD_SIZE
        val messageId = System.currentTimeMillis().toInt()

        for (i in 0 until totalFragments) {
            val startIndex = i * FRAGMENT_PAYLOAD_SIZE
            val endIndex = minOf(startIndex + FRAGMENT_PAYLOAD_SIZE, messageBytes.size)
            val payloadData = messageBytes.sliceArray(startIndex until endIndex)

            val fragment = createFragmentHeader(messageId, i, totalFragments, payloadData)
            fragments.add(fragment)
        }

        return fragments
    }

    /** Create a fragment with header */
    private fun createFragmentHeader(
            messageId: Int,
            fragmentIndex: Int,
            totalFragments: Int,
            payload: ByteArray
    ): ByteArray {
        val fragment = ByteArray(FRAGMENT_HEADER_SIZE + payload.size)

        // Message ID (4 bytes)
        fragment[0] = (messageId and 0xFF).toByte()
        fragment[1] = ((messageId shr 8) and 0xFF).toByte()
        fragment[2] = ((messageId shr 16) and 0xFF).toByte()
        fragment[3] = ((messageId shr 24) and 0xFF).toByte()

        // Fragment index (2 bytes)
        fragment[4] = (fragmentIndex and 0xFF).toByte()
        fragment[5] = ((fragmentIndex shr 8) and 0xFF).toByte()

        // Total fragments (2 bytes)
        fragment[6] = (totalFragments and 0xFF).toByte()
        fragment[7] = ((totalFragments shr 8) and 0xFF).toByte()

        // Payload length (2 bytes)
        fragment[8] = (payload.size and 0xFF).toByte()
        fragment[9] = ((payload.size shr 8) and 0xFF).toByte()

        // Checksum (2 bytes)
        val checksum = calculateChecksum(payload)
        fragment[10] = (checksum and 0xFF).toByte()
        fragment[11] = ((checksum shr 8) and 0xFF).toByte()

        // Copy payload
        System.arraycopy(payload, 0, fragment, FRAGMENT_HEADER_SIZE, payload.size)

        return fragment
    }

    /** Calculate checksum for data integrity */
    private fun calculateChecksum(data: ByteArray): Int {
        var checksum = 0
        for (byte in data) {
            checksum = checksum xor (byte.toInt() and 0xFF)
            for (i in 0 until 8) {
                checksum =
                        if (checksum and 1 != 0) {
                            (checksum shr 1) xor 0x8408
                        } else {
                            checksum shr 1
                        }
            }
        }
        return checksum and 0xFFFF
    }

    /** Parse fragment header and extract data */
    private fun parseFragment(data: ByteArray): MessageFragment? {
        if (data.size < FRAGMENT_HEADER_SIZE) return null

        try {
            val messageId =
                    (data[0].toInt() and 0xFF) or
                            ((data[1].toInt() and 0xFF) shl 8) or
                            ((data[2].toInt() and 0xFF) shl 16) or
                            ((data[3].toInt() and 0xFF) shl 24)

            val fragmentIndex = (data[4].toInt() and 0xFF) or ((data[5].toInt() and 0xFF) shl 8)
            val totalFragments = (data[6].toInt() and 0xFF) or ((data[7].toInt() and 0xFF) shl 8)
            val payloadLength = (data[8].toInt() and 0xFF) or ((data[9].toInt() and 0xFF) shl 8)
            val checksum = (data[10].toInt() and 0xFF) or ((data[11].toInt() and 0xFF) shl 8)

            val payload =
                    data.sliceArray(FRAGMENT_HEADER_SIZE until FRAGMENT_HEADER_SIZE + payloadLength)

            // Verify checksum
            val calculatedChecksum = calculateChecksum(payload)
            if (calculatedChecksum != checksum) {
                Log.w(
                        TAG,
                        "Fragment checksum mismatch: expected $checksum, got $calculatedChecksum"
                )
                return null
            }

            return MessageFragment(messageId, fragmentIndex, totalFragments, payload)
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing fragment", e)
            return null
        }
    }

    /** Handle incoming fragment and attempt message reassembly */
    private fun handleFragment(fragment: MessageFragment) {
        val messageId = fragment.messageId.toString()
        Log.d(TAG, "handleFragment: Processing fragment for messageId=$messageId")

        // Initialize fragment buffer if needed
        if (!fragmentBuffers.containsKey(messageId)) {
            fragmentBuffers[messageId] = MutableList(fragment.totalFragments) { null }
            fragmentTimestamps[messageId] = System.currentTimeMillis()
            Log.d(TAG, "handleFragment: Initialized buffer for messageId=$messageId with ${fragment.totalFragments} fragments")
        }

        // Add fragment to buffer
        val buffer = fragmentBuffers[messageId]!!
        if (fragment.fragmentIndex < buffer.size) {
            buffer[fragment.fragmentIndex] = fragment
            Log.d(TAG, "handleFragment: Added fragment ${fragment.fragmentIndex}/${fragment.totalFragments} for messageId=$messageId")
        }

        // Check if all fragments received
        val receivedFragments = buffer.count { it != null }
        Log.d(TAG, "handleFragment: Have $receivedFragments/${fragment.totalFragments} fragments for messageId=$messageId")
        
        if (buffer.all { it != null }) {
            Log.d(TAG, "handleFragment: All fragments received for messageId=$messageId, reassembling...")
            
            val completeMessage = reassembleMessage(buffer.filterNotNull())
            if (completeMessage != null) {
                currentMessage = completeMessage
                Log.d(TAG, "handleFragment: Successfully reassembled message, notifying Flutter layer")

                // Notify Flutter layer
                mainHandler.post {
                    methodChannel?.invokeMethod(
                            "onMessageReceived",
                            mapOf("messageData" to completeMessage)
                    )
                }

                // Clean up
                fragmentBuffers.remove(messageId)
                fragmentTimestamps.remove(messageId)
            } else {
                Log.e(TAG, "handleFragment: Failed to reassemble message for messageId=$messageId")
            }
        }
    }

    /** Reassemble fragments into complete message */
    private fun reassembleMessage(fragments: List<MessageFragment>): ByteArray? {
        return try {
            val sortedFragments = fragments.sortedBy { it.fragmentIndex }
            val messageData = mutableListOf<Byte>()

            for (fragment in sortedFragments) {
                messageData.addAll(fragment.payload.toList())
            }

            messageData.toByteArray()
        } catch (e: Exception) {
            Log.e(TAG, "Error reassembling message", e)
            null
        }
    }

    /** Clean up expired fragment buffers */
    private fun cleanupExpiredFragments() {
        val currentTime = System.currentTimeMillis()
        val expiredIds = mutableListOf<String>()

        for ((messageId, timestamp) in fragmentTimestamps) {
            if (currentTime - timestamp > 30000) { // 30 second timeout
                expiredIds.add(messageId)
            }
        }

        for (messageId in expiredIds) {
            fragmentBuffers.remove(messageId)
            fragmentTimestamps.remove(messageId)
        }
    }

    // GATT Server Callback
    private val gattServerCallback =
            object : BluetoothGattServerCallback() {
                override fun onConnectionStateChange(
                        device: BluetoothDevice,
                        status: Int,
                        newState: Int
                ) {
                    super.onConnectionStateChange(device, status, newState)

                    when (newState) {
                        BluetoothProfile.STATE_CONNECTED -> {
                            Log.d(TAG, "Device connected: ${device.address}")
                            connectedDevices[device.address] = device

                            mainHandler.post {
                                methodChannel?.invokeMethod(
                                        "onDeviceConnected",
                                        mapOf(
                                                "deviceId" to device.address,
                                                "deviceName" to device.name
                                        )
                                )
                            }
                        }
                        BluetoothProfile.STATE_DISCONNECTED -> {
                            Log.d(TAG, "Device disconnected: ${device.address}")
                            connectedDevices.remove(device.address)

                            mainHandler.post {
                                methodChannel?.invokeMethod(
                                        "onDeviceDisconnected",
                                        mapOf("deviceId" to device.address)
                                )
                            }
                        }
                    }
                }

                override fun onCharacteristicReadRequest(
                        device: BluetoothDevice,
                        requestId: Int,
                        offset: Int,
                        characteristic: BluetoothGattCharacteristic
                ) {
                    super.onCharacteristicReadRequest(device, requestId, offset, characteristic)

                    when (characteristic.uuid) {
                        READ_CHARACTERISTIC_UUID -> {
                            val response = currentMessage ?: ByteArray(0)
                            gattServer?.sendResponse(
                                    device,
                                    requestId,
                                    BluetoothGatt.GATT_SUCCESS,
                                    offset,
                                    response
                            )
                        }
                        NOTIFY_CHARACTERISTIC_UUID -> {
                            gattServer?.sendResponse(
                                    device,
                                    requestId,
                                    BluetoothGatt.GATT_SUCCESS,
                                    offset,
                                    ByteArray(0)
                            )
                        }
                    }
                }

                override fun onCharacteristicWriteRequest(
                        device: BluetoothDevice,
                        requestId: Int,
                        characteristic: BluetoothGattCharacteristic,
                        preparedWrite: Boolean,
                        responseNeeded: Boolean,
                        offset: Int,
                        value: ByteArray
                ) {
                    super.onCharacteristicWriteRequest(
                            device,
                            requestId,
                            characteristic,
                            preparedWrite,
                            responseNeeded,
                            offset,
                            value
                    )

                    when (characteristic.uuid) {
                        WRITE_CHARACTERISTIC_UUID -> {
                            Log.d(TAG, "onCharacteristicWriteRequest: Received ${value.size} bytes from ${device.address}")
                            
                            val fragment = parseFragment(value)
                            if (fragment != null) {
                                Log.d(TAG, "Parsed fragment: messageId=${fragment.messageId}, fragmentIndex=${fragment.fragmentIndex}, totalFragments=${fragment.totalFragments}")
                                handleFragment(fragment)
                            } else {
                                Log.e(TAG, "Failed to parse fragment from received data")
                            }

                            if (responseNeeded) {
                                gattServer?.sendResponse(
                                        device,
                                        requestId,
                                        BluetoothGatt.GATT_SUCCESS,
                                        offset,
                                        null
                                )
                            }
                        }
                    }
                }

                override fun onDescriptorWriteRequest(
                        device: BluetoothDevice,
                        requestId: Int,
                        descriptor: BluetoothGattDescriptor,
                        preparedWrite: Boolean,
                        responseNeeded: Boolean,
                        offset: Int,
                        value: ByteArray
                ) {
                    super.onDescriptorWriteRequest(
                            device,
                            requestId,
                            descriptor,
                            preparedWrite,
                            responseNeeded,
                            offset,
                            value
                    )

                    if (responseNeeded) {
                        gattServer?.sendResponse(
                                device,
                                requestId,
                                BluetoothGatt.GATT_SUCCESS,
                                offset,
                                null
                        )
                    }
                }
            }

    // Advertising Callback
    private val advertiseCallback =
            object : AdvertiseCallback() {
                override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
                    super.onStartSuccess(settingsInEffect)
                    Log.d(TAG, "Advertising started successfully")

                    mainHandler.post { methodChannel?.invokeMethod("onAdvertisingStarted", null) }
                }

                override fun onStartFailure(errorCode: Int) {
                    super.onStartFailure(errorCode)
                    Log.e(TAG, "Advertising failed to start: $errorCode")

                    mainHandler.post {
                        methodChannel?.invokeMethod(
                                "onAdvertisingFailed",
                                mapOf("errorCode" to errorCode)
                        )
                    }
                }
            }

    // Method Channel Handler
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startServer" -> {
                val success = startServer()
                result.success(success)
            }
            "stopServer" -> {
                stopServer()
                result.success(true)
            }
            "sendMessage" -> {
                val messageData = call.argument<ByteArray>("messageData")
                if (messageData != null) {
                    sendMessage(messageData)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Message data is null", null)
                }
            }
            "getConnectedDevices" -> {
                val devices =
                        connectedDevices.values.map { device ->
                            mapOf("deviceId" to device.address, "deviceName" to device.name)
                        }
                result.success(devices)
            }
            "cleanupFragments" -> {
                cleanupExpiredFragments()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /** Data class for message fragments */
    private data class MessageFragment(
            val messageId: Int,
            val fragmentIndex: Int,
            val totalFragments: Int,
            val payload: ByteArray
    )
}
