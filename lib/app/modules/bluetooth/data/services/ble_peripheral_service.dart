import 'dart:async';
import 'package:flutter/services.dart';
import '../../domain/constants/ble_constants.dart';
import '../../domain/models/message_models.dart';

/// BLE Peripheral Service
///
/// This service manages the native Android GATT server via method channels,
/// providing a high-level Dart API for peripheral functionality.
class BlePeripheralService {
  static const MethodChannel _channel = MethodChannel(
    'disasterlink/ble_peripheral',
  );

  // Stream controllers for events
  final StreamController<Map<String, dynamic>> _deviceConnectedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _deviceDisconnectedController =
      StreamController<String>.broadcast();
  final StreamController<DisasterLinkMessage> _messageReceivedController =
      StreamController<DisasterLinkMessage>.broadcast();
  final StreamController<bool> _advertisingStatusController =
      StreamController<bool>.broadcast();

  // Current state
  BlePeripheralState _state = BlePeripheralState.stopped;
  final List<Map<String, dynamic>> _connectedDevices = [];

  // Message handling
  final MessageReassembler _messageReassembler = MessageReassembler();
  Timer? _cleanupTimer;

  /// Singleton instance
  static BlePeripheralService? _instance;

  BlePeripheralService._();

  /// Get singleton instance
  static BlePeripheralService get instance {
    _instance ??= BlePeripheralService._();
    return _instance!;
  }

  /// Stream of device connection events
  Stream<Map<String, dynamic>> get deviceConnectedStream =>
      _deviceConnectedController.stream;

  /// Stream of device disconnection events
  Stream<String> get deviceDisconnectedStream =>
      _deviceDisconnectedController.stream;

  /// Stream of received messages
  Stream<DisasterLinkMessage> get messageReceivedStream =>
      _messageReceivedController.stream;

  /// Stream of advertising status changes
  Stream<bool> get advertisingStatusStream =>
      _advertisingStatusController.stream;

  /// Current peripheral state
  BlePeripheralState get state => _state;

  /// List of connected devices
  List<Map<String, dynamic>> get connectedDevices =>
      List.unmodifiable(_connectedDevices);

  /// Initialize the peripheral service
  Future<void> initialize() async {
    _setupMethodChannelHandler();
    _startCleanupTimer();
  }

  /// Setup method channel to handle callbacks from native code
  void _setupMethodChannelHandler() {
    _channel.setMethodCallHandler((call) async {
      print('DEBUG_PERIPHERAL: Method call received: ${call.method}');
      print('DEBUG_PERIPHERAL: Arguments type: ${call.arguments?.runtimeType}');

      switch (call.method) {
        case 'onDeviceConnected':
          _handleDeviceConnected(call.arguments);
          break;
        case 'onDeviceDisconnected':
          _handleDeviceDisconnected(call.arguments);
          break;
        case 'onMessageReceived':
          print('DEBUG_PERIPHERAL: Message received from Kotlin side');
          _handleMessageReceived(call.arguments);
          break;
        case 'onAdvertisingStarted':
          _handleAdvertisingStarted();
          break;
        case 'onAdvertisingFailed':
          _handleAdvertisingFailed(call.arguments);
          break;
        default:
          print('Unknown method call: ${call.method}');
      }
    });
  }

  /// Start the GATT server and begin advertising
  Future<bool> startServer() async {
    try {
      _state = BlePeripheralState.starting;

      final result = await _channel.invokeMethod<bool>('startServer');

      if (result == true) {
        // Don't set to advertising here - wait for the native callback
        print('BLE Peripheral server started successfully');
        return true;
      } else {
        _state = BlePeripheralState.failed;
        print('Failed to start BLE Peripheral server');
        return false;
      }
    } catch (e) {
      _state = BlePeripheralState.failed;
      print('Error starting BLE Peripheral server: $e');
      return false;
    }
  }

  /// Stop the GATT server and advertising
  Future<bool> stopServer() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopServer');

      if (result == true) {
        _state = BlePeripheralState.stopped;
        _connectedDevices.clear();
        print('BLE Peripheral server stopped successfully');
        return true;
      } else {
        print('Failed to stop BLE Peripheral server');
        return false;
      }
    } catch (e) {
      print('Error stopping BLE Peripheral server: $e');
      return false;
    }
  }

  /// Send a message to all connected devices
  Future<bool> sendMessage(DisasterLinkMessage message) async {
    try {
      if (_connectedDevices.isEmpty) {
        print('No connected devices to send message to');
        return false;
      }

      final messageBytes = message.toBytes();
      final result = await _channel.invokeMethod<bool>('sendMessage', {
        'messageData': messageBytes,
      });

      if (result == true) {
        print('Message sent successfully: ${message.id}');
        return true;
      } else {
        print('Failed to send message: ${message.id}');
        return false;
      }
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  /// Get currently connected devices
  Future<List<Map<String, dynamic>>> getConnectedDevices() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getConnectedDevices',
      );
      return result?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      print('Error getting connected devices: $e');
      return [];
    }
  }

  /// Clean up expired message fragments
  Future<void> cleanupFragments() async {
    try {
      await _channel.invokeMethod('cleanupFragments');
      _messageReassembler.cleanupExpiredFragments();
    } catch (e) {
      print('Error cleaning up fragments: $e');
    }
  }

  /// Handle device connection event
  void _handleDeviceConnected(Map<String, dynamic> deviceInfo) {
    final deviceId = deviceInfo['deviceId'] as String;
    final deviceName = deviceInfo['deviceName'] as String?;

    final device = {
      'deviceId': deviceId,
      'deviceName': deviceName ?? 'Unknown Device',
      'connectedAt': DateTime.now().toIso8601String(),
    };

    _connectedDevices.add(device);
    _deviceConnectedController.add(device);

    print('Device connected: $deviceId (${device['deviceName']})');
  }

  /// Handle device disconnection event
  void _handleDeviceDisconnected(Map<String, dynamic> deviceInfo) {
    final deviceId = deviceInfo['deviceId'] as String;

    _connectedDevices.removeWhere((device) => device['deviceId'] == deviceId);
    _deviceDisconnectedController.add(deviceId);

    print('Device disconnected: $deviceId');
  }

  /// Handle received message event
  void _handleMessageReceived(Map<String, dynamic> data) {
    try {
      print('DEBUG_PERIPHERAL_RECEIVE: Raw data received: $data');

      // Handle different data formats from Kotlin
      Uint8List messageData;
      if (data['messageData'] is Uint8List) {
        messageData = data['messageData'] as Uint8List;
      } else if (data['messageData'] is List<int>) {
        messageData = Uint8List.fromList(List<int>.from(data['messageData']));
      } else if (data['messageData'] is String) {
        // Handle base64 encoded data
        messageData = Uint8List.fromList(
          List<int>.from(data['messageData'].codeUnits),
        );
      } else {
        print(
          'ERROR: Unknown message data format: ${data['messageData'].runtimeType}',
        );
        return;
      }

      print('DEBUG_PERIPHERAL_RECEIVE: Processing ${messageData.length} bytes');

      final message = DisasterLinkMessage.fromBytes(messageData);

      _messageReceivedController.add(message);
      print('Message received: ${message.id} from ${message.senderName}');
    } catch (e, stackTrace) {
      print('Error handling received message: $e');
      print('Stack trace: $stackTrace');
      print('Raw data that caused error: $data');
    }
  }

  /// Handle advertising started event
  void _handleAdvertisingStarted() {
    _state = BlePeripheralState.advertising;
    _advertisingStatusController.add(true);
    print('BLE advertising started');
  }

  /// Handle advertising failed event
  void _handleAdvertisingFailed(Map<String, dynamic> errorInfo) {
    _state = BlePeripheralState.failed;
    _advertisingStatusController.add(false);

    final errorCode = errorInfo['errorCode'] as int;
    print('BLE advertising failed with error code: $errorCode');
  }

  /// Start cleanup timer for expired fragments
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      cleanupFragments();
    });
  }

  /// Dispose of resources
  void dispose() {
    _cleanupTimer?.cancel();
    _deviceConnectedController.close();
    _deviceDisconnectedController.close();
    _messageReceivedController.close();
    _advertisingStatusController.close();
  }
}

/// Convenient wrapper for common peripheral operations
class BlePeripheralManager {
  final BlePeripheralService _service = BlePeripheralService.instance;

  /// Initialize the peripheral manager
  Future<void> initialize() async {
    await _service.initialize();
  }

  /// Start peripheral mode
  Future<bool> startPeripheralMode() async {
    return await _service.startServer();
  }

  /// Stop peripheral mode
  Future<bool> stopPeripheralMode() async {
    return await _service.stopServer();
  }

  /// Send an emergency SOS message
  Future<bool> sendEmergencySOS({
    required String senderId,
    required String senderName,
    required double latitude,
    required double longitude,
    String? additionalInfo,
  }) async {
    final message = MessageFactory.createEmergencySOS(
      senderId: senderId,
      senderName: senderName,
      latitude: latitude,
      longitude: longitude,
      additionalInfo: additionalInfo,
    );

    return await _service.sendMessage(message);
  }

  /// Send a text message
  Future<bool> sendTextMessage({
    required String senderId,
    required String senderName,
    required String text,
    String? recipientId,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    final message = MessageFactory.createTextMessage(
      senderId: senderId,
      senderName: senderName,
      text: text,
      recipientId: recipientId,
      priority: priority,
    );

    return await _service.sendMessage(message);
  }

  /// Send a location sharing message
  Future<bool> sendLocationShare({
    required String senderId,
    required String senderName,
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    final message = MessageFactory.createLocationShare(
      senderId: senderId,
      senderName: senderName,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    );

    return await _service.sendMessage(message);
  }

  /// Send a resource request message
  Future<bool> sendResourceRequest({
    required String senderId,
    required String senderName,
    required String resourceType,
    required int quantity,
    String? description,
    MessagePriority priority = MessagePriority.high,
  }) async {
    final message = MessageFactory.createResourceRequest(
      senderId: senderId,
      senderName: senderName,
      resourceType: resourceType,
      quantity: quantity,
      description: description,
      priority: priority,
    );

    return await _service.sendMessage(message);
  }

  /// Send a status update message
  Future<bool> sendStatusUpdate({
    required String senderId,
    required String senderName,
    required String status,
    Map<String, dynamic>? additionalData,
  }) async {
    final message = MessageFactory.createStatusUpdate(
      senderId: senderId,
      senderName: senderName,
      status: status,
      additionalData: additionalData,
    );

    return await _service.sendMessage(message);
  }

  /// Get service instance for direct access
  BlePeripheralService get service => _service;
}
