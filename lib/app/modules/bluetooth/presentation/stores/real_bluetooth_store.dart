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

      // Debug logging for message sending
      debugLogMessageSend(message, targetDevice);

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

        // Analyze performance after successful send
        debugAnalyzeMessagePerformance();

        // Track delivery status for this message
        debugTrackMessageDelivery(message, false);
      } else {
        _setError('Failed to send message');

        // Debug the failed transmission
        print('DEBUG_SEND_FAILURE: Message ${message.id} failed to send');
        print('  Central connection state: $_centralConnectionState');
        print('  Peripheral state: $_peripheralState');
        print('  Connected devices count: ${_connectedDevices.length}');
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

      // Debug logging for emergency SOS sending
      debugLogMessageSend(message, targetDevice);

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
        // Analyze performance after successful send
        debugAnalyzeMessagePerformance();
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

      // Debug logging for location share sending
      debugLogMessageSend(message, targetDevice);

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
        // Analyze performance after successful send
        debugAnalyzeMessagePerformance();
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

    // Debug logging for received message
    debugLogMessageReceive(message, source);

    print(
      'Message received from $source: ${message.id} - ${message.type.value}',
    );

    // Check if this is an acknowledgment for one of our sent messages
    bool isAckForOurMessage = false;
    if (message.type == MessageType.acknowledgment &&
        message.payload.containsKey('originalMessageId')) {
      final originalMsgId = message.payload['originalMessageId'] as String;
      final sentMessage = _sentMessages.any((m) => m.id == originalMsgId);
      if (sentMessage) {
        isAckForOurMessage = true;
        print(
          'DEBUG_ACK_RECEIVED: Received acknowledgment for message $originalMsgId',
        );
      }
    }

    // Handle acknowledgment if required
    if (message.requiresAck) {
      _sendAcknowledgment(message);
    }

    // Enhanced tracking for message delivery status
    debugTrackMessageDelivery(message, isAckForOurMessage);

    // Analyze message performance after receiving a new message
    debugAnalyzeMessagePerformance();

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

      // Debug logging for acknowledgment sending
      debugLogMessageSend(ackMessage, null);

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

  /// Debug utility: Log message sending details
  void debugLogMessageSend(
    DisasterLinkMessage message,
    BluetoothDevice? targetDevice,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final targetInfo = targetDevice != null
        ? 'to specific device ${targetDevice.remoteId.str}'
        : 'as broadcast';

    print('DEBUG_SEND [$timestamp] Message ${message.id}:');
    print('  Type: ${message.type.value}');
    print('  Sender: ${message.senderName} (${message.senderId})');
    print('  Payload: ${_truncateContent(message.payload.toString())}');
    print('  Target: $targetInfo');
    print('  Size: ${_estimateMessageSize(message)} bytes');
  }

  /// Debug utility: Log message receiving details
  void debugLogMessageReceive(DisasterLinkMessage message, String source) {
    final timestamp = DateTime.now().toIso8601String();

    print('DEBUG_RECEIVE [$timestamp] Message ${message.id}:');
    print('  Type: ${message.type.value}');
    print('  Sender: ${message.senderName} (${message.senderId})');
    print('  Payload: ${_truncateContent(message.payload.toString())}');
    print('  Source: $source');
    print('  Receipt Time: $timestamp');

    // Additional analytics for message types
    switch (message.type) {
      case MessageType.textMessage:
        final textContent = message.payload['text'] as String?;
        print('  Text Length: ${textContent?.length ?? 0} chars');
        break;
      case MessageType.emergencySos:
        if (message.payload.containsKey('location')) {
          final location = message.payload['location'];
          print(
            '  Location: lat=${location['latitude']}, lng=${location['longitude']}',
          );
        }
        break;
      case MessageType.locationShare:
        if (message.payload.containsKey('location')) {
          final location = message.payload['location'];
          print(
            '  Location: lat=${location['latitude']}, lng=${location['longitude']}',
          );
          print(
            '  Location Name: ${message.payload['locationName'] ?? 'Unnamed location'}',
          );
        }
        break;
      default:
        break;
    }
  }

  /// Enhanced debug utility: Track message delivery status
  void debugTrackMessageDelivery(
    DisasterLinkMessage message,
    bool isAcknowledged,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final age = DateTime.now().difference(message.timestamp).inSeconds;

    print('DEBUG_MESSAGE_TRACKING [$timestamp]:');
    print('  Message ID: ${message.id}');
    print('  Type: ${message.type.value}');
    print('  Age: $age seconds');
    print('  Is Acknowledged: $isAcknowledged');

    // Check for connected devices that could have received this message
    print('  Connected Central Devices: ${_connectedDevices.length}');
    for (final device in _connectedDevices) {
      print('    - ${device.remoteId.str} (${device.platformName})');
    }

    print(
      '  Connected Peripheral Devices: ${_peripheralConnectedDevices.length}',
    );
    for (final entry in _peripheralConnectedDevices.entries) {
      print('    - ${entry.key} (${entry.value['deviceName'] ?? 'Unknown'})');
    }

    // Check connectivity details
    print('  Bluetooth Enabled: $_isBluetoothEnabled');
    print('  Central State: $_centralConnectionState');
    print('  Peripheral State: $_peripheralState');
  }

  /// Debug utility: Check message transmissions for a specific time window
  Future<void> debugCheckRecentMessageTransmissions({
    int lastMinutes = 5,
  }) async {
    final cutoffTime = DateTime.now().subtract(Duration(minutes: lastMinutes));

    // Recent messages
    final recentSent = _sentMessages
        .where((msg) => msg.timestamp.isAfter(cutoffTime))
        .toList();
    final recentReceived = _receivedMessages
        .where((msg) => msg.timestamp.isAfter(cutoffTime))
        .toList();

    print('DEBUG_RECENT_MESSAGES (Last $lastMinutes minutes):');
    print('  Recent Sent: ${recentSent.length}');
    print('  Recent Received: ${recentReceived.length}');

    // Check for sent messages without acknowledgments
    if (recentSent.isNotEmpty) {
      final pendingAcks = recentSent
          .where(
            (msg) =>
                msg.requiresAck &&
                !_receivedMessages.any(
                  (ack) =>
                      ack.type == MessageType.acknowledgment &&
                      ack.payload['originalMessageId'] == msg.id,
                ),
          )
          .toList();

      print(
        '  Pending Acknowledgments: ${pendingAcks.length}/${recentSent.where((m) => m.requiresAck).length}',
      );

      for (final msg in pendingAcks) {
        final age = DateTime.now().difference(msg.timestamp).inSeconds;
        print('    - ID: ${msg.id}, Type: ${msg.type.value}, Age: ${age}s');
      }
    }

    // Check message delivery channels
    print('  Central Service Status: Available');
    print('  Peripheral Service Status: Available');

    try {
      // Check BLE state
      final isBluetoothOn = await FlutterBluePlus.isOn;
      print('  Bluetooth Hardware Status: ${isBluetoothOn ? "ON" : "OFF"}');
    } catch (e) {
      print('  Error checking Bluetooth status: $e');
    }
  }

  /// Helper to truncate content for logging
  String _truncateContent(String content) {
    const maxLength = 100;
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  /// Helper to estimate message size in bytes
  int _estimateMessageSize(DisasterLinkMessage message) {
    // Rough estimate of JSON serialization size
    final jsonString = message.toJson().toString();
    return jsonString.length;
  }

  /// Debug utility: Analyze message transmission performance
  void debugAnalyzeMessagePerformance() {
    if (_sentMessages.isEmpty && _receivedMessages.isEmpty) {
      print('DEBUG_PERFORMANCE: No messages to analyze');
      return;
    }

    // Message type distribution
    final Map<MessageType, int> sentByType = {};
    final Map<MessageType, int> receivedByType = {};

    for (final msg in _sentMessages) {
      sentByType[msg.type] = (sentByType[msg.type] ?? 0) + 1;
    }

    for (final msg in _receivedMessages) {
      receivedByType[msg.type] = (receivedByType[msg.type] ?? 0) + 1;
    }

    print('DEBUG_PERFORMANCE ANALYSIS:');
    print('  Total Sent: ${_sentMessages.length}');
    print('  Total Received: ${_receivedMessages.length}');
    print('  Sent by type: ${_formatTypeDistribution(sentByType)}');
    print('  Received by type: ${_formatTypeDistribution(receivedByType)}');

    // Calculate success rate for acknowledgments if any
    final sentWithAckRequired = _sentMessages
        .where((m) => m.requiresAck)
        .length;
    final receivedAcks = _receivedMessages
        .where((m) => m.type == MessageType.acknowledgment)
        .length;

    if (sentWithAckRequired > 0) {
      final ackRate = (receivedAcks / sentWithAckRequired) * 100;
      print('  Acknowledgment rate: ${ackRate.toStringAsFixed(1)}%');
    }
  }

  /// Format type distribution for logging
  String _formatTypeDistribution(Map<MessageType, int> typeMap) {
    return typeMap.entries.map((e) => '${e.key.value}:${e.value}').join(', ');
  }

  /// Debug utility: Track message delivery and acknowledgment by ID
  void debugTrackMessageDeliveryById(String messageId) {
    DisasterLinkMessage? message;
    try {
      message = _sentMessages.firstWhere((m) => m.id == messageId);
    } catch (e) {
      message = null;
    }

    if (message == null) {
      print('DEBUG_TRACK: Message $messageId not found in sent messages');
      return;
    }

    // Find any acknowledgments for this message
    final acks = _receivedMessages
        .where(
          (m) =>
              m.type == MessageType.acknowledgment &&
              m.payload['originalMessageId'] == messageId,
        )
        .toList();

    print('DEBUG_TRACK Message $messageId:');
    print('  Type: ${message.type.value}');
    print('  Sent time: ${message.timestamp}');
    print('  Current time: ${DateTime.now().toIso8601String()}');
    print('  Requires acknowledgment: ${message.requiresAck}');
    print('  Acknowledgments received: ${acks.length}');

    if (acks.isNotEmpty) {
      for (final ack in acks) {
        // Calculate time difference
        final latencyMs = ack.timestamp
            .difference(message.timestamp)
            .inMilliseconds;

        print('  Ack from: ${ack.senderName} (${ack.senderId})');
        print('  Ack latency: ${latencyMs}ms');
      }
    }

    // Show current connection status
    print('  Current connections: ${totalConnectedDevices}');
    print('  Central connections: ${_connectedDevices.length}');
    print('  Peripheral connections: ${_peripheralConnectedDevices.length}');
  }

  /// Debug utility: Check recent message transmissions by count
  void debugCheckRecentMessageTransmissionsByCount({int count = 5}) {
    final recentMessages = _sentMessages.length > count
        ? _sentMessages.sublist(_sentMessages.length - count)
        : _sentMessages;

    print('DEBUG_RECENT_TRANSMISSIONS:');
    print('  Showing last ${recentMessages.length} messages:');

    for (final msg in recentMessages) {
      final acks = _receivedMessages
          .where(
            (m) =>
                m.type == MessageType.acknowledgment &&
                m.payload['originalMessageId'] == msg.id,
          )
          .length;

      print('  Message ${msg.id}:');
      print('    Type: ${msg.type.value}');
      print('    Sent: ${msg.timestamp}');
      print('    Requires ack: ${msg.requiresAck}');
      print('    Acks received: $acks');
    }

    // List connected devices
    print('  Connected devices:');
    for (final device in _connectedDevices) {
      print('    Central: ${device.platformName} (${device.remoteId.str})');
    }

    for (final entry in _peripheralConnectedDevices.entries) {
      print(
        '    Peripheral: ${entry.value['deviceName'] ?? 'Unknown'} (${entry.key})',
      );
    }
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
