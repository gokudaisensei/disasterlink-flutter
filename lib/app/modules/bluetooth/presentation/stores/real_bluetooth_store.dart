import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/constants/ble_constants.dart';
import '../../domain/models/message_models.dart';
import '../../data/services/ble_central_service.dart';
import '../../data/services/ble_peripheral_service.dart';

/// Enhanced BLE Store for real P2P messaging
///
/// This store replaces the mock implementation with real BLE functionality
/// using flutter_blue_plus for central operations and native Android GATT
/// server for peripheral operations.
class BluetoothStore extends ChangeNotifier {
  // Services
  final BleCentralService _centralService = BleCentralService.instance;
  final BlePeripheralService _peripheralService = BlePeripheralService.instance;

  // State
  bool _isBluetoothEnabled = false;
  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isPeripheralActive = false;
  BleConnectionState _centralConnectionState = BleConnectionState.disconnected;
  BlePeripheralState _peripheralState = BlePeripheralState.stopped;

  // Devices
  final List<BluetoothDevice> _discoveredDevices = [];
  final List<BluetoothDevice> _connectedDevices = [];
  final Map<String, Map<String, dynamic>> _peripheralConnectedDevices = {};

  // Messages
  final List<DisasterLinkMessage> _receivedMessages = [];
  final List<DisasterLinkMessage> _sentMessages = [];

  // Error handling
  String? _errorMessage;

  // Subscriptions
  final List<StreamSubscription> _subscriptions = [];

  // Device info
  String? _deviceId;
  String? _deviceName;

  // Getters
  bool get isBluetoothEnabled => _isBluetoothEnabled;
  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  bool get isPeripheralActive => _isPeripheralActive;
  BleConnectionState get centralConnectionState => _centralConnectionState;
  BlePeripheralState get peripheralState => _peripheralState;
  List<BluetoothDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);
  List<BluetoothDevice> get connectedDevices =>
      List.unmodifiable(_connectedDevices);
  List<Map<String, dynamic>> get peripheralConnectedDevices =>
      List.unmodifiable(_peripheralConnectedDevices.values);
  List<DisasterLinkMessage> get receivedMessages =>
      List.unmodifiable(_receivedMessages);
  List<DisasterLinkMessage> get sentMessages =>
      List.unmodifiable(_sentMessages);
  String? get errorMessage => _errorMessage;
  String? get deviceId => _deviceId;
  String? get deviceName => _deviceName;

  // Computed properties
  int get totalConnectedDevices =>
      _connectedDevices.length + _peripheralConnectedDevices.length;
  int get totalDiscoveredDevices => _discoveredDevices.length;
  bool get hasActiveConnections => totalConnectedDevices > 0;

  /// Initialize the BLE store
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _clearError();

      // Initialize device info
      _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      _deviceName =
          'DisasterLink-${_deviceId!.substring(_deviceId!.length - 6)}';

      // Check Bluetooth support and state
      _isBluetoothEnabled = await _centralService.isBluetoothEnabled;

      // Initialize services
      final centralInitialized = await _centralService.initialize();
      await _peripheralService.initialize();

      if (!centralInitialized) {
        _setError('Failed to initialize BLE central service');
        return;
      }

      // Setup event listeners
      _setupEventListeners();

      _isInitialized = true;
      print('BLE Store initialized successfully');
    } catch (e) {
      _setError('Failed to initialize BLE: $e');
      print('BLE Store initialization error: $e');
    }

    notifyListeners();
  }

  /// Setup event listeners for BLE services
  void _setupEventListeners() {
    // Central service events
    _subscriptions.add(
      _centralService.deviceFoundStream.listen(
        (device) {
          _handleDeviceFound(device);
        },
        onError: (error) {
          print('Device found stream error: $error');
        },
      ),
    );

    _subscriptions.add(
      _centralService.deviceConnectedStream.listen(
        (device) {
          _handleCentralDeviceConnected(device);
        },
        onError: (error) {
          print('Device connected stream error: $error');
        },
      ),
    );

    _subscriptions.add(
      _centralService.deviceDisconnectedStream.listen(
        (device) {
          _handleCentralDeviceDisconnected(device);
        },
        onError: (error) {
          print('Device disconnected stream error: $error');
        },
      ),
    );

    _subscriptions.add(
      _centralService.messageReceivedStream.listen(
        (message) {
          _handleMessageReceived(message, 'central');
        },
        onError: (error) {
          print('Message received stream error: $error');
        },
      ),
    );

    _subscriptions.add(
      _centralService.scanStateStream.listen(
        (state) {
          _handleScanStateChanged(state);
        },
        onError: (error) {
          print('Scan state stream error: $error');
        },
      ),
    );

    // Peripheral service events
    _subscriptions.add(
      _peripheralService.deviceConnectedStream.listen(
        (deviceInfo) {
          _handlePeripheralDeviceConnected(deviceInfo);
        },
        onError: (error) {
          print('Peripheral device connected stream error: $error');
        },
      ),
    );

    _subscriptions.add(
      _peripheralService.deviceDisconnectedStream.listen(
        (deviceId) {
          _handlePeripheralDeviceDisconnected(deviceId);
        },
        onError: (error) {
          print('Peripheral device disconnected stream error: $error');
        },
      ),
    );

    _subscriptions.add(
      _peripheralService.messageReceivedStream.listen(
        (message) {
          _handleMessageReceived(message, 'peripheral');
        },
        onError: (error) {
          print('Peripheral message received stream error: $error');
        },
      ),
    );

    _subscriptions.add(
      _peripheralService.advertisingStatusStream.listen(
        (isAdvertising) {
          _handleAdvertisingStatusChanged(isAdvertising);
        },
        onError: (error) {
          print('Advertising status stream error: $error');
        },
      ),
    );
  }

  /// Toggle Bluetooth functionality
  Future<void> toggleBluetooth() async {
    if (!_isInitialized) {
      await initialize();
      return;
    }

    try {
      _clearError();

      if (_isBluetoothEnabled) {
        // Disable Bluetooth operations
        await stopScanning();
        await stopPeripheralMode();
        await disconnectAllDevices();
        _isBluetoothEnabled = false;
      } else {
        // Enable Bluetooth operations
        _isBluetoothEnabled = await _centralService.isBluetoothEnabled;
        if (!_isBluetoothEnabled) {
          _setError('Bluetooth is not enabled on this device');
        }
      }
    } catch (e) {
      _setError('Failed to toggle Bluetooth: $e');
    }

    notifyListeners();
  }

  /// Start scanning for devices
  Future<void> startScanning({Duration? timeout}) async {
    if (!_isBluetoothEnabled || _isScanning) return;

    try {
      _clearError();

      final success = await _centralService.startScanning(timeout: timeout);
      if (!success) {
        _setError('Failed to start scanning');
      }
    } catch (e) {
      _setError('Scanning error: $e');
    }

    notifyListeners();
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    if (!_isScanning) return;

    try {
      await _centralService.stopScanning();
    } catch (e) {
      print('Error stopping scan: $e');
    }

    notifyListeners();
  }

  /// Start peripheral mode
  Future<void> startPeripheralMode() async {
    if (!_isBluetoothEnabled || _isPeripheralActive) return;

    try {
      _clearError();
      _peripheralState = BlePeripheralState.starting;
      notifyListeners();

      final success = await _peripheralService.startServer();
      if (!success) {
        _peripheralState = BlePeripheralState.failed;
        _setError('Failed to start peripheral mode');
      }
      // Note: _peripheralState will be updated to advertising via _handleAdvertisingStatusChanged
    } catch (e) {
      _peripheralState = BlePeripheralState.failed;
      _setError('Peripheral mode error: $e');
    }

    notifyListeners();
  }

  /// Stop peripheral mode
  Future<void> stopPeripheralMode() async {
    if (!_isPeripheralActive) return;

    try {
      _peripheralState = BlePeripheralState.stopped;
      await _peripheralService.stopServer();
      _isPeripheralActive = false;
    } catch (e) {
      print('Error stopping peripheral mode: $e');
    }

    notifyListeners();
  }

  /// Connect to a device
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (!_isBluetoothEnabled) return;

    try {
      _clearError();
      _centralConnectionState = BleConnectionState.connecting;
      notifyListeners();

      final success = await _centralService.connectToDevice(device);
      if (!success) {
        _setError('Failed to connect to ${device.platformName}');
        _centralConnectionState = BleConnectionState.failed;
      }
    } catch (e) {
      _setError('Connection error: $e');
      _centralConnectionState = BleConnectionState.failed;
    }

    notifyListeners();
  }

  /// Disconnect from a device
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    try {
      _clearError();
      _centralConnectionState = BleConnectionState.disconnecting;
      notifyListeners();

      final success = await _centralService.disconnectFromDevice(device);
      if (!success) {
        _setError('Failed to disconnect from ${device.platformName}');
      }
    } catch (e) {
      _setError('Disconnection error: $e');
    }

    notifyListeners();
  }

  /// Disconnect from all devices
  Future<void> disconnectAllDevices() async {
    try {
      // Disconnect central connections
      final centralDisconnectTasks = _connectedDevices.map(
        (device) => _centralService.disconnectFromDevice(device),
      );

      // Stop peripheral server
      await _peripheralService.stopServer();

      await Future.wait(centralDisconnectTasks);
    } catch (e) {
      print('Error disconnecting all devices: $e');
    }

    notifyListeners();
  }

  /// Send a text message
  Future<void> sendTextMessage({
    required String text,
    BluetoothDevice? targetDevice,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    if (!_isBluetoothEnabled) return;

    try {
      _clearError();

      final message = MessageFactory.createTextMessage(
        senderId: _deviceId!,
        senderName: _deviceName!,
        text: text,
        priority: priority,
      );

      bool success = false;

      // Send via central service
      if (targetDevice != null) {
        success = await _centralService.sendMessageToDevice(
          targetDevice,
          message,
        );
      } else {
        success = await _centralService.broadcastMessage(message);
      }

      // Also send via peripheral service if no specific target
      if (targetDevice == null) {
        final peripheralSuccess = await _peripheralService.sendMessage(message);
        success = success || peripheralSuccess;
      }

      if (success) {
        _sentMessages.add(message);
        print('Message sent successfully: ${message.id}');
      } else {
        _setError('Failed to send message');
      }
    } catch (e) {
      _setError('Send message error: $e');
    }

    notifyListeners();
  }

  /// Send an emergency SOS message
  Future<void> sendEmergencySOS({
    String? additionalInfo,
    BluetoothDevice? targetDevice,
  }) async {
    if (!_isBluetoothEnabled) return;

    try {
      _clearError();

      // Get current location
      final position = await _getCurrentLocation();

      final message = MessageFactory.createEmergencySOS(
        senderId: _deviceId!,
        senderName: _deviceName!,
        latitude: position.latitude,
        longitude: position.longitude,
        additionalInfo: additionalInfo,
      );

      bool success = false;

      // Send via central service
      if (targetDevice != null) {
        success = await _centralService.sendMessageToDevice(
          targetDevice,
          message,
        );
      } else {
        success = await _centralService.broadcastMessage(message);
      }

      // Also send via peripheral service if no specific target
      if (targetDevice == null) {
        final peripheralSuccess = await _peripheralService.sendMessage(message);
        success = success || peripheralSuccess;
      }

      if (success) {
        _sentMessages.add(message);
        print('Emergency SOS sent successfully: ${message.id}');
      } else {
        _setError('Failed to send emergency SOS');
      }
    } catch (e) {
      _setError('Send emergency SOS error: $e');
    }

    notifyListeners();
  }

  /// Send a location sharing message
  Future<void> sendLocationShare({
    String? locationName,
    BluetoothDevice? targetDevice,
  }) async {
    if (!_isBluetoothEnabled) return;

    try {
      _clearError();

      // Get current location
      final position = await _getCurrentLocation();

      final message = MessageFactory.createLocationShare(
        senderId: _deviceId!,
        senderName: _deviceName!,
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: locationName,
      );

      bool success = false;

      // Send via central service
      if (targetDevice != null) {
        success = await _centralService.sendMessageToDevice(
          targetDevice,
          message,
        );
      } else {
        success = await _centralService.broadcastMessage(message);
      }

      // Also send via peripheral service if no specific target
      if (targetDevice == null) {
        final peripheralSuccess = await _peripheralService.sendMessage(message);
        success = success || peripheralSuccess;
      }

      if (success) {
        _sentMessages.add(message);
        print('Location shared successfully: ${message.id}');
      } else {
        _setError('Failed to share location');
      }
    } catch (e) {
      _setError('Share location error: $e');
    }

    notifyListeners();
  }

  /// Get current location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Handle device found
  void _handleDeviceFound(BluetoothDevice device) {
    final existingIndex = _discoveredDevices.indexWhere(
      (d) => d.remoteId == device.remoteId,
    );

    if (existingIndex >= 0) {
      _discoveredDevices[existingIndex] = device;
    } else {
      _discoveredDevices.add(device);
    }

    notifyListeners();
  }

  /// Handle central device connected
  void _handleCentralDeviceConnected(BluetoothDevice device) {
    final existingIndex = _connectedDevices.indexWhere(
      (d) => d.remoteId == device.remoteId,
    );

    if (existingIndex >= 0) {
      _connectedDevices[existingIndex] = device;
    } else {
      _connectedDevices.add(device);
    }

    _centralConnectionState = BleConnectionState.connected;
    notifyListeners();
  }

  /// Handle central device disconnected
  void _handleCentralDeviceDisconnected(BluetoothDevice device) {
    _connectedDevices.removeWhere((d) => d.remoteId == device.remoteId);

    if (_connectedDevices.isEmpty) {
      _centralConnectionState = BleConnectionState.disconnected;
    }

    notifyListeners();
  }

  /// Handle peripheral device connected
  void _handlePeripheralDeviceConnected(Map<String, dynamic> deviceInfo) {
    final deviceId = deviceInfo['deviceId'] as String;
    _peripheralConnectedDevices[deviceId] = deviceInfo;
    notifyListeners();
  }

  /// Handle peripheral device disconnected
  void _handlePeripheralDeviceDisconnected(String deviceId) {
    _peripheralConnectedDevices.remove(deviceId);
    notifyListeners();
  }

  /// Handle message received
  void _handleMessageReceived(DisasterLinkMessage message, String source) {
    _receivedMessages.add(message);
    print(
      'Message received from $source: ${message.id} - ${message.type.value}',
    );

    // Handle acknowledgment if required
    if (message.requiresAck) {
      _sendAcknowledgment(message);
    }

    notifyListeners();
  }

  /// Send acknowledgment for a message
  Future<void> _sendAcknowledgment(DisasterLinkMessage originalMessage) async {
    try {
      final ackMessage = MessageFactory.createAcknowledgment(
        senderId: _deviceId!,
        senderName: _deviceName!,
        originalMessageId: originalMessage.id,
        recipientId: originalMessage.senderId,
      );

      // Send acknowledgment via both services
      await _centralService.broadcastMessage(ackMessage);
      await _peripheralService.sendMessage(ackMessage);

      _sentMessages.add(ackMessage);
    } catch (e) {
      print('Error sending acknowledgment: $e');
    }
  }

  /// Handle scan state changed
  void _handleScanStateChanged(BleScanState state) {
    _isScanning = state == BleScanState.scanning;
    notifyListeners();
  }

  /// Handle advertising status changed
  void _handleAdvertisingStatusChanged(bool isAdvertising) {
    _isPeripheralActive = isAdvertising;
    _peripheralState = isAdvertising
        ? BlePeripheralState.advertising
        : BlePeripheralState.stopped;
    print(
      'Advertising status changed: $isAdvertising, peripheral state: $_peripheralState',
    );
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    print('BLE Store Error: $message');
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error and update state
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'discoveredDevices': _discoveredDevices.length,
      'connectedDevices': totalConnectedDevices,
      'centralConnections': _connectedDevices.length,
      'peripheralConnections': _peripheralConnectedDevices.length,
      'receivedMessages': _receivedMessages.length,
      'sentMessages': _sentMessages.length,
      'isScanning': _isScanning,
      'isPeripheralActive': _isPeripheralActive,
      'centralConnectionState': _centralConnectionState.name,
      'peripheralState': _peripheralState.name,
    };
  }

  /// Get message statistics
  Map<String, dynamic> getMessageStats() {
    final messagesByType = <String, int>{};
    for (final message in _receivedMessages) {
      messagesByType[message.type.value] =
          (messagesByType[message.type.value] ?? 0) + 1;
    }

    return {
      'totalReceived': _receivedMessages.length,
      'totalSent': _sentMessages.length,
      'messagesByType': messagesByType,
      'emergencyMessages': _receivedMessages
          .where((m) => m.type == MessageType.emergencySos)
          .length,
    };
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Dispose services
    _centralService.dispose();
    _peripheralService.dispose();

    super.dispose();
  }
}
