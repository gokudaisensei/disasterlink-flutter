import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/constants/ble_constants.dart';
import '../../domain/models/message_models.dart';

/// BLE Central Service using Flutter Blue Plus
///
/// This service handles BLE central operations including:
/// - Scanning for DisasterLink devices
/// - Connecting to peripherals
/// - Reading/writing message fragments
/// - Handling notifications
class BleCentralService {
  // Stream controllers for events
  final StreamController<BluetoothDevice> _deviceFoundController =
      StreamController<BluetoothDevice>.broadcast();
  final StreamController<BluetoothDevice> _deviceConnectedController =
      StreamController<BluetoothDevice>.broadcast();
  final StreamController<BluetoothDevice> _deviceDisconnectedController =
      StreamController<BluetoothDevice>.broadcast();
  final StreamController<DisasterLinkMessage> _messageReceivedController =
      StreamController<DisasterLinkMessage>.broadcast();
  final StreamController<BleScanState> _scanStateController =
      StreamController<BleScanState>.broadcast();

  // Current state
  BleScanState _scanState = BleScanState.idle;
  final Map<String, BluetoothDevice> _discoveredDevices = {};
  final Map<String, BluetoothDevice> _connectedDevices = {};
  final Map<String, List<BluetoothCharacteristic>> _deviceCharacteristics = {};
  final Map<String, MessageReassembler> _messageReassemblers = {};

  // Scan subscription
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // Connection subscriptions
  final Map<String, StreamSubscription<BluetoothConnectionState>>
  _connectionSubscriptions = {};
  final Map<String, StreamSubscription<List<int>>> _notificationSubscriptions =
      {};

  // Cleanup timer
  Timer? _cleanupTimer;

  /// Singleton instance
  static BleCentralService? _instance;

  BleCentralService._();

  /// Get singleton instance
  static BleCentralService get instance {
    _instance ??= BleCentralService._();
    return _instance!;
  }

  /// Stream of discovered devices
  Stream<BluetoothDevice> get deviceFoundStream =>
      _deviceFoundController.stream;

  /// Stream of device connection events
  Stream<BluetoothDevice> get deviceConnectedStream =>
      _deviceConnectedController.stream;

  /// Stream of device disconnection events
  Stream<BluetoothDevice> get deviceDisconnectedStream =>
      _deviceDisconnectedController.stream;

  /// Stream of received messages
  Stream<DisasterLinkMessage> get messageReceivedStream =>
      _messageReceivedController.stream;

  /// Stream of scan state changes
  Stream<BleScanState> get scanStateStream => _scanStateController.stream;

  /// Current scan state
  BleScanState get scanState => _scanState;

  /// List of discovered devices
  List<BluetoothDevice> get discoveredDevices =>
      _discoveredDevices.values.toList();

  /// List of connected devices
  List<BluetoothDevice> get connectedDevices =>
      _connectedDevices.values.toList();

  /// Check if Bluetooth is enabled
  Future<bool> get isBluetoothEnabled async {
    try {
      return await FlutterBluePlus.isOn;
    } catch (e) {
      print('Error checking Bluetooth state: $e');
      return false;
    }
  }

  /// Initialize the central service
  Future<bool> initialize() async {
    try {
      // Request permissions
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        print('BLE permissions not granted');
        return false;
      }

      // Check if Bluetooth is supported
      if (!await FlutterBluePlus.isSupported) {
        print('Bluetooth not supported on this device');
        return false;
      }

      // Start cleanup timer
      _startCleanupTimer();

      print('BLE Central Service initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing BLE Central Service: $e');
      return false;
    }
  }

  /// Request necessary permissions
  Future<bool> _requestPermissions() async {
    try {
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.locationWhenInUse,
      ];

      final results = await permissions.request();

      return results.values.every(
        (status) =>
            status == PermissionStatus.granted ||
            status ==
                PermissionStatus
                    .permanentlyDenied, // Some devices might not have certain permissions
      );
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  /// Start scanning for DisasterLink devices
  Future<bool> startScanning({Duration? timeout}) async {
    try {
      if (_scanState == BleScanState.scanning) {
        print('Already scanning');
        return true;
      }

      if (!await isBluetoothEnabled) {
        print('Bluetooth is not enabled');
        return false;
      }

      _scanState = BleScanState.scanning;
      _scanStateController.add(_scanState);

      // Clear previous results
      _discoveredDevices.clear();

      // Start scanning with service filter
      await FlutterBluePlus.startScan(
        withServices: [Guid(kDisasterLinkServiceUuid)],
        timeout: timeout ?? const Duration(seconds: 30),
        continuousUpdates: true,
        removeIfGone: const Duration(seconds: 5),
      );

      // Listen for scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          for (final result in results) {
            _handleScanResult(result);
          }
        },
        onError: (error) {
          print('Scan error: $error');
          _scanState = BleScanState.failed;
          _scanStateController.add(_scanState);
        },
      );

      // Handle scan completion
      FlutterBluePlus.isScanning.listen((isScanning) {
        if (!isScanning && _scanState == BleScanState.scanning) {
          _scanState = BleScanState.completed;
          _scanStateController.add(_scanState);
        }
      });

      print('Started scanning for DisasterLink devices');
      return true;
    } catch (e) {
      print('Error starting scan: $e');
      _scanState = BleScanState.failed;
      _scanStateController.add(_scanState);
      return false;
    }
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    try {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _scanSubscription = null;

      _scanState = BleScanState.idle;
      _scanStateController.add(_scanState);

      print('Stopped scanning');
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  /// Handle scan result
  void _handleScanResult(ScanResult result) {
    final device = result.device;
    final deviceId = device.remoteId.toString();

    if (!_discoveredDevices.containsKey(deviceId)) {
      _discoveredDevices[deviceId] = device;
      _deviceFoundController.add(device);

      print(
        'Discovered DisasterLink device: ${device.platformName} (${device.remoteId})',
      );
    }
  }

  /// Connect to a device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      final deviceId = device.remoteId.toString();

      if (_connectedDevices.containsKey(deviceId)) {
        print('Already connected to device: $deviceId');
        return true;
      }

      print('Connecting to device: ${device.platformName} ($deviceId)');

      // Connect to the device
      await device.connect(timeout: const Duration(seconds: 10));

      // Discover services
      final services = await device.discoverServices();
      final disasterLinkService = services.firstWhere(
        (service) =>
            service.uuid.toString().toLowerCase() ==
            kDisasterLinkServiceUuid.toLowerCase(),
        orElse: () => throw Exception('DisasterLink service not found'),
      );

      // Get characteristics
      final characteristics = disasterLinkService.characteristics;
      _deviceCharacteristics[deviceId] = characteristics;

      // Subscribe to notifications
      final notifyCharacteristic = characteristics.firstWhere(
        (char) =>
            char.uuid.toString().toLowerCase() ==
            BleCharacteristics.notifyCharacteristicUuid.toLowerCase(),
        orElse: () => throw Exception('Notify characteristic not found'),
      );

      await notifyCharacteristic.setNotifyValue(true);

      // Listen for notifications
      _notificationSubscriptions[deviceId] = notifyCharacteristic
          .onValueReceived
          .listen(
            (value) {
              _handleNotification(deviceId, Uint8List.fromList(value));
            },
            onError: (error) {
              print('Notification error for device $deviceId: $error');
            },
          );

      // Monitor connection state
      _connectionSubscriptions[deviceId] = device.connectionState.listen(
        (state) {
          _handleConnectionStateChange(device, state);
        },
        onError: (error) {
          print('Connection state error for device $deviceId: $error');
        },
      );

      _connectedDevices[deviceId] = device;
      _messageReassemblers[deviceId] = MessageReassembler();
      _deviceConnectedController.add(device);

      print('Successfully connected to device: $deviceId');
      return true;
    } catch (e) {
      print('Error connecting to device: $e');
      return false;
    }
  }

  /// Disconnect from a device
  Future<bool> disconnectFromDevice(BluetoothDevice device) async {
    try {
      final deviceId = device.remoteId.toString();

      // Cancel subscriptions
      _connectionSubscriptions[deviceId]?.cancel();
      _connectionSubscriptions.remove(deviceId);

      _notificationSubscriptions[deviceId]?.cancel();
      _notificationSubscriptions.remove(deviceId);

      // Disconnect
      await device.disconnect();

      // Clean up
      _connectedDevices.remove(deviceId);
      _deviceCharacteristics.remove(deviceId);
      _messageReassemblers.remove(deviceId);

      _deviceDisconnectedController.add(device);

      print('Disconnected from device: $deviceId');
      return true;
    } catch (e) {
      print('Error disconnecting from device: $e');
      return false;
    }
  }

  /// Send a message to a specific device
  Future<bool> sendMessageToDevice(
    BluetoothDevice device,
    DisasterLinkMessage message,
  ) async {
    try {
      final deviceId = device.remoteId.toString();
      final characteristics = _deviceCharacteristics[deviceId];

      if (characteristics == null) {
        print('No characteristics found for device: $deviceId');
        return false;
      }

      final writeCharacteristic = characteristics.firstWhere(
        (char) =>
            char.uuid.toString().toLowerCase() ==
            BleCharacteristics.writeCharacteristicUuid.toLowerCase(),
        orElse: () => throw Exception('Write characteristic not found'),
      );

      // Create fragments
      final fragments = MessageFragment.createFragments(message);

      // Send each fragment
      for (final fragment in fragments) {
        final fragmentBytes = fragment.toBytes();

        // Split into chunks if needed (MTU limitation)
        final chunks = _splitIntoChunks(fragmentBytes, 512);

        for (final chunk in chunks) {
          await writeCharacteristic.write(chunk, withoutResponse: true);
          await Future.delayed(
            const Duration(milliseconds: 50),
          ); // Small delay between chunks
        }
      }

      print('Successfully sent message to device: $deviceId');
      return true;
    } catch (e) {
      print('Error sending message to device: $e');
      return false;
    }
  }

  /// Send a message to all connected devices
  Future<bool> broadcastMessage(DisasterLinkMessage message) async {
    try {
      if (_connectedDevices.isEmpty) {
        print('No connected devices to broadcast to');
        return false;
      }

      final results = await Future.wait(
        _connectedDevices.values.map(
          (device) => sendMessageToDevice(device, message),
        ),
      );

      final successCount = results.where((success) => success).length;
      print('Broadcast message to $successCount/${results.length} devices');

      return successCount > 0;
    } catch (e) {
      print('Error broadcasting message: $e');
      return false;
    }
  }

  /// Read the latest message from a device
  Future<DisasterLinkMessage?> readMessageFromDevice(
    BluetoothDevice device,
  ) async {
    try {
      final deviceId = device.remoteId.toString();
      final characteristics = _deviceCharacteristics[deviceId];

      if (characteristics == null) {
        print('No characteristics found for device: $deviceId');
        return null;
      }

      final readCharacteristic = characteristics.firstWhere(
        (char) =>
            char.uuid.toString().toLowerCase() ==
            BleCharacteristics.readCharacteristicUuid.toLowerCase(),
        orElse: () => throw Exception('Read characteristic not found'),
      );

      final value = await readCharacteristic.read();

      if (value.isNotEmpty) {
        return DisasterLinkMessage.fromBytes(Uint8List.fromList(value));
      }

      return null;
    } catch (e) {
      print('Error reading message from device: $e');
      return null;
    }
  }

  /// Handle connection state changes
  void _handleConnectionStateChange(
    BluetoothDevice device,
    BluetoothConnectionState state,
  ) {
    final deviceId = device.remoteId.toString();

    switch (state) {
      case BluetoothConnectionState.connected:
        print('Device $deviceId connected');
        break;
      case BluetoothConnectionState.disconnected:
        print('Device $deviceId disconnected');
        _cleanupDevice(device);
        break;
      case BluetoothConnectionState.connecting:
        print('Device $deviceId connecting');
        break;
      case BluetoothConnectionState.disconnecting:
        print('Device $deviceId disconnecting');
        break;
    }
  }

  /// Handle incoming notifications
  void _handleNotification(String deviceId, Uint8List data) {
    try {
      final reassembler = _messageReassemblers[deviceId];
      if (reassembler == null) {
        print('No message reassembler for device: $deviceId');
        return;
      }

      // Parse fragment
      final fragment = MessageFragment.fromBytes(data);

      // Attempt to reassemble message
      final completeMessage = reassembler.addFragment(fragment);

      if (completeMessage != null) {
        _messageReceivedController.add(completeMessage);
        print(
          'Received complete message from device $deviceId: ${completeMessage.id}',
        );
      }
    } catch (e) {
      print('Error handling notification from device $deviceId: $e');
    }
  }

  /// Clean up device resources
  void _cleanupDevice(BluetoothDevice device) {
    final deviceId = device.remoteId.toString();

    _connectionSubscriptions[deviceId]?.cancel();
    _connectionSubscriptions.remove(deviceId);

    _notificationSubscriptions[deviceId]?.cancel();
    _notificationSubscriptions.remove(deviceId);

    _connectedDevices.remove(deviceId);
    _deviceCharacteristics.remove(deviceId);
    _messageReassemblers.remove(deviceId);

    _deviceDisconnectedController.add(device);
  }

  /// Split data into chunks for MTU limitation
  List<List<int>> _splitIntoChunks(Uint8List data, int chunkSize) {
    final chunks = <List<int>>[];

    for (int i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      chunks.add(data.sublist(i, end));
    }

    return chunks;
  }

  /// Start cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _cleanupExpiredFragments();
    });
  }

  /// Clean up expired fragments
  void _cleanupExpiredFragments() {
    for (final reassembler in _messageReassemblers.values) {
      reassembler.cleanupExpiredFragments();
    }
  }

  /// Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'discoveredDevices': _discoveredDevices.length,
      'connectedDevices': _connectedDevices.length,
      'scanState': _scanState.name,
      'messageReassemblers': _messageReassemblers.length,
    };
  }

  /// Dispose of all resources
  void dispose() {
    _cleanupTimer?.cancel();

    // Cancel scan
    _scanSubscription?.cancel();

    // Disconnect all devices
    for (final device in _connectedDevices.values) {
      device.disconnect();
    }

    // Cancel all subscriptions
    for (final subscription in _connectionSubscriptions.values) {
      subscription.cancel();
    }

    for (final subscription in _notificationSubscriptions.values) {
      subscription.cancel();
    }

    // Close stream controllers
    _deviceFoundController.close();
    _deviceConnectedController.close();
    _deviceDisconnectedController.close();
    _messageReceivedController.close();
    _scanStateController.close();

    print('BLE Central Service disposed');
  }
}

/// Convenient wrapper for common central operations
class BleCentralManager {
  final BleCentralService _service = BleCentralService.instance;

  /// Initialize the central manager
  Future<bool> initialize() async {
    return await _service.initialize();
  }

  /// Start scanning for devices
  Future<bool> startScanning({Duration? timeout}) async {
    return await _service.startScanning(timeout: timeout);
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    await _service.stopScanning();
  }

  /// Connect to a device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    return await _service.connectToDevice(device);
  }

  /// Disconnect from a device
  Future<bool> disconnectFromDevice(BluetoothDevice device) async {
    return await _service.disconnectFromDevice(device);
  }

  /// Send an emergency SOS message
  Future<bool> sendEmergencySOS({
    required String senderId,
    required String senderName,
    required double latitude,
    required double longitude,
    String? additionalInfo,
    BluetoothDevice? targetDevice,
  }) async {
    final message = MessageFactory.createEmergencySOS(
      senderId: senderId,
      senderName: senderName,
      latitude: latitude,
      longitude: longitude,
      additionalInfo: additionalInfo,
    );

    if (targetDevice != null) {
      return await _service.sendMessageToDevice(targetDevice, message);
    } else {
      return await _service.broadcastMessage(message);
    }
  }

  /// Send a text message
  Future<bool> sendTextMessage({
    required String senderId,
    required String senderName,
    required String text,
    String? recipientId,
    MessagePriority priority = MessagePriority.normal,
    BluetoothDevice? targetDevice,
  }) async {
    final message = MessageFactory.createTextMessage(
      senderId: senderId,
      senderName: senderName,
      text: text,
      recipientId: recipientId,
      priority: priority,
    );

    if (targetDevice != null) {
      return await _service.sendMessageToDevice(targetDevice, message);
    } else {
      return await _service.broadcastMessage(message);
    }
  }

  /// Get service instance for direct access
  BleCentralService get service => _service;
}
