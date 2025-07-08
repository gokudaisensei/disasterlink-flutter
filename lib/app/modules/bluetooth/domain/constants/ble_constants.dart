/// Custom BLE Service UUID for DisasterLink Emergency Communication
/// This service handles all emergency messaging between devices
const String kDisasterLinkServiceUuid = 'b32b86a1-a04c-4db3-8276-b17ec127dab1';

/// Characteristic UUIDs for the DisasterLink Service
class BleCharacteristics {
  /// Write characteristic - Central writes message fragments to peripheral
  /// Properties: WRITE, WRITE_WITHOUT_RESPONSE
  static const String writeCharacteristicUuid =
      '25c54c03-9f43-4015-ba94-c923cbfd7a4b';

  /// Notify characteristic - Peripheral sends message fragments to central
  /// Properties: NOTIFY, READ
  static const String notifyCharacteristicUuid =
      'c7911626-4838-4781-aae8-a5e6ea601ed2';

  /// Read characteristic - Central can read the latest complete message
  /// Properties: READ
  static const String readCharacteristicUuid =
      'd10fe796-9f87-43ab-ba06-00530ebee963';
}

/// BLE Protocol Constants
class BleProtocol {
  /// Maximum BLE MTU size (minus headers)
  static const int maxMtuSize = 512;

  /// Fragment payload size (accounting for our header)
  static const int fragmentPayloadSize = maxMtuSize - fragmentHeaderSize;

  /// Size of fragment header in bytes
  static const int fragmentHeaderSize = 12;

  /// Maximum message size before fragmentation (8KB)
  static const int maxMessageSize = 8192;

  /// Connection timeout in milliseconds
  static const int connectionTimeout = 10000;

  /// Scan timeout in milliseconds
  static const int scanTimeout = 30000;

  /// Message timeout in milliseconds
  static const int messageTimeout = 30000;

  /// Retry attempts for failed operations
  static const int maxRetryAttempts = 3;

  /// Delay between retry attempts in milliseconds
  static const int retryDelay = 1000;
}

/// Message Types for DisasterLink Protocol
enum MessageType {
  /// Emergency SOS broadcast
  emergencySos('emergency_sos'),

  /// General text message
  textMessage('text_message'),

  /// Location sharing
  locationShare('location_share'),

  /// Resource request
  resourceRequest('resource_request'),

  /// Status update
  statusUpdate('status_update'),

  /// System acknowledgment
  acknowledgment('acknowledgment'),

  /// Heartbeat/keep-alive
  heartbeat('heartbeat');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.textMessage,
    );
  }
}

/// Message Priority Levels
enum MessagePriority {
  /// Critical emergency messages
  critical(0),

  /// High priority messages
  high(1),

  /// Normal priority messages
  normal(2),

  /// Low priority messages
  low(3);

  const MessagePriority(this.value);
  final int value;

  static MessagePriority fromInt(int value) {
    return MessagePriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => MessagePriority.normal,
    );
  }
}

/// Device Types for BLE identification
enum BleDeviceType {
  /// Mobile phone
  phone('phone'),

  /// Tablet device
  tablet('tablet'),

  /// Laptop/computer
  laptop('laptop'),

  /// Emergency response unit
  emergencyUnit('emergency_unit'),

  /// Base station
  baseStation('base_station'),

  /// Unknown device type
  unknown('unknown');

  const BleDeviceType(this.value);
  final String value;

  static BleDeviceType fromString(String value) {
    return BleDeviceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => BleDeviceType.unknown,
    );
  }
}

/// Connection States
enum BleConnectionState {
  /// Device is disconnected
  disconnected,

  /// Attempting to connect
  connecting,

  /// Device is connected
  connected,

  /// Connection failed
  failed,

  /// Device is being disconnected
  disconnecting,
}

/// Scanning States
enum BleScanState {
  /// Not scanning
  idle,

  /// Currently scanning
  scanning,

  /// Scan completed
  completed,

  /// Scan failed
  failed,
}

/// Peripheral Server States
enum BlePeripheralState {
  /// Server is stopped
  stopped,

  /// Server is starting
  starting,

  /// Server is running and advertising
  advertising,

  /// Server failed to start
  failed,
}
