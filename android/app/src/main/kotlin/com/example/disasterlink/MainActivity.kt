package com.example.disasterlink

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.disasterlink.ble.BleGattServer

class MainActivity : FlutterActivity() {
    private lateinit var bleGattServer: BleGattServer
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize BLE GATT Server
        bleGattServer = BleGattServer(this)
        
        // Register method channel
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BleGattServer.CHANNEL_NAME)
        channel.setMethodCallHandler(bleGattServer)
        
        // Initialize the server
        bleGattServer.initialize(channel)
    }
}
