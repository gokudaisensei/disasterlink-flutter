import 'dart:convert';
import 'dart:typed_data';
import '../constants/ble_constants.dart';

/// Represents a complete message in the DisasterLink system
class DisasterLinkMessage {
  /// Unique identifier for the message
  final String id;

  /// Type of message
  final MessageType type;

  /// Priority level
  final MessagePriority priority;

  /// Sender device ID
  final String senderId;

  /// Sender device name
  final String senderName;

  /// Recipient device ID (null for broadcast)
  final String? recipientId;

  /// Message content/payload
  final Map<String, dynamic> payload;

  /// Timestamp when message was created
  final DateTime timestamp;

  /// Message time-to-live in seconds
  final int ttl;

  /// Whether this message requires acknowledgment
  final bool requiresAck;

  /// Number of hops this message has traveled
  final int hopCount;

  const DisasterLinkMessage({
    required this.id,
    required this.type,
    required this.priority,
    required this.senderId,
    required this.senderName,
    this.recipientId,
    required this.payload,
    required this.timestamp,
    this.ttl = 3600, // 1 hour default TTL
    this.requiresAck = false,
    this.hopCount = 0,
  });

  /// Convert message to JSON for transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'priority': priority.value,
      'senderId': senderId,
      'senderName': senderName,
      'recipientId': recipientId,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl,
      'requiresAck': requiresAck,
      'hopCount': hopCount,
    };
  }

  /// Create message from JSON
  factory DisasterLinkMessage.fromJson(Map<String, dynamic> json) {
    return DisasterLinkMessage(
      id: json['id'] as String,
      type: MessageType.fromString(json['type'] as String),
      priority: MessagePriority.fromInt(json['priority'] as int),
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      recipientId: json['recipientId'] as String?,
      payload: json['payload'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      ttl: json['ttl'] as int? ?? 3600,
      requiresAck: json['requiresAck'] as bool? ?? false,
      hopCount: json['hopCount'] as int? ?? 0,
    );
  }

  /// Convert message to UTF-8 encoded bytes
  Uint8List toBytes() {
    final jsonString = jsonEncode(toJson());
    return Uint8List.fromList(utf8.encode(jsonString));
  }

  /// Create message from UTF-8 encoded bytes
  factory DisasterLinkMessage.fromBytes(Uint8List bytes) {
    final jsonString = utf8.decode(bytes);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return DisasterLinkMessage.fromJson(json);
  }

  /// Create a copy of this message with updated fields
  DisasterLinkMessage copyWith({
    String? id,
    MessageType? type,
    MessagePriority? priority,
    String? senderId,
    String? senderName,
    String? recipientId,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    int? ttl,
    bool? requiresAck,
    int? hopCount,
  }) {
    return DisasterLinkMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      recipientId: recipientId ?? this.recipientId,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      ttl: ttl ?? this.ttl,
      requiresAck: requiresAck ?? this.requiresAck,
      hopCount: hopCount ?? this.hopCount,
    );
  }

  /// Check if message has expired
  bool get isExpired {
    final expiryTime = timestamp.add(Duration(seconds: ttl));
    return DateTime.now().isAfter(expiryTime);
  }

  /// Get message size in bytes
  int get sizeInBytes => toBytes().length;

  /// Check if message needs fragmentation
  bool get needsFragmentation => sizeInBytes > BleProtocol.fragmentPayloadSize;

  @override
  String toString() {
    return 'DisasterLinkMessage(id: $id, type: ${type.value}, priority: ${priority.value}, '
        'sender: $senderName, size: ${sizeInBytes}B)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisasterLinkMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents a fragment of a larger message
class MessageFragment {
  /// Unique identifier for the original message
  final String messageId;

  /// Fragment sequence number (0-based)
  final int fragmentIndex;

  /// Total number of fragments for this message
  final int totalFragments;

  /// Fragment payload data
  final Uint8List data;

  /// Timestamp when fragment was created
  final DateTime timestamp;

  /// CRC32 checksum for integrity verification
  final int checksum;

  const MessageFragment({
    required this.messageId,
    required this.fragmentIndex,
    required this.totalFragments,
    required this.data,
    required this.timestamp,
    required this.checksum,
  });

  /// Convert fragment to bytes for transmission
  Uint8List toBytes() {
    final buffer = ByteData(BleProtocol.fragmentHeaderSize + data.length);
    int offset = 0;

    // Message ID (first 4 bytes of UUID hash)
    final messageIdHash = messageId.hashCode;
    buffer.setUint32(offset, messageIdHash, Endian.little);
    offset += 4;

    // Fragment index (2 bytes)
    buffer.setUint16(offset, fragmentIndex, Endian.little);
    offset += 2;

    // Total fragments (2 bytes)
    buffer.setUint16(offset, totalFragments, Endian.little);
    offset += 2;

    // Data length (2 bytes)
    buffer.setUint16(offset, data.length, Endian.little);
    offset += 2;

    // Checksum (2 bytes)
    buffer.setUint16(offset, checksum & 0xFFFF, Endian.little);
    offset += 2;

    // Copy payload data
    final result = Uint8List(buffer.lengthInBytes);
    result.setRange(
      0,
      BleProtocol.fragmentHeaderSize,
      buffer.buffer.asUint8List(),
    );
    result.setRange(BleProtocol.fragmentHeaderSize, result.length, data);

    return result;
  }

  /// Create fragment from transmitted bytes
  factory MessageFragment.fromBytes(Uint8List bytes) {
    if (bytes.length < BleProtocol.fragmentHeaderSize) {
      throw ArgumentError(
        'Fragment too small: ${bytes.length} < ${BleProtocol.fragmentHeaderSize}',
      );
    }

    final buffer = ByteData.sublistView(
      bytes,
      0,
      BleProtocol.fragmentHeaderSize,
    );
    int offset = 0;

    // Extract message ID hash
    final messageIdHash = buffer.getUint32(offset, Endian.little);
    offset += 4;

    // Extract fragment index
    final fragmentIndex = buffer.getUint16(offset, Endian.little);
    offset += 2;

    // Extract total fragments
    final totalFragments = buffer.getUint16(offset, Endian.little);
    offset += 2;

    // Extract data length
    final dataLength = buffer.getUint16(offset, Endian.little);
    offset += 2;

    // Extract checksum
    final checksum = buffer.getUint16(offset, Endian.little);
    offset += 2;

    // Extract payload data
    final data = bytes.sublist(
      BleProtocol.fragmentHeaderSize,
      BleProtocol.fragmentHeaderSize + dataLength,
    );

    return MessageFragment(
      messageId: messageIdHash.toString(), // Using hash as ID for now
      fragmentIndex: fragmentIndex,
      totalFragments: totalFragments,
      data: data,
      timestamp: DateTime.now(),
      checksum: checksum,
    );
  }

  /// Calculate CRC32 checksum for data integrity
  static int calculateChecksum(Uint8List data) {
    // Simple checksum calculation - in production, use proper CRC32
    int checksum = 0;
    for (int byte in data) {
      checksum ^= byte;
      for (int i = 0; i < 8; i++) {
        if (checksum & 1 != 0) {
          checksum = (checksum >> 1) ^ 0x8408;
        } else {
          checksum >>= 1;
        }
      }
    }
    return checksum & 0xFFFF;
  }

  /// Verify fragment integrity
  bool verifyIntegrity() {
    final calculatedChecksum = calculateChecksum(data);
    return calculatedChecksum == checksum;
  }

  /// Create fragments from a complete message
  static List<MessageFragment> createFragments(DisasterLinkMessage message) {
    final messageBytes = message.toBytes();
    final fragments = <MessageFragment>[];

    // Calculate number of fragments needed
    final totalFragments =
        (messageBytes.length / BleProtocol.fragmentPayloadSize).ceil();

    for (int i = 0; i < totalFragments; i++) {
      final startIndex = i * BleProtocol.fragmentPayloadSize;
      final endIndex = (startIndex + BleProtocol.fragmentPayloadSize).clamp(
        0,
        messageBytes.length,
      );

      final fragmentData = messageBytes.sublist(startIndex, endIndex);
      final checksum = calculateChecksum(fragmentData);

      final fragment = MessageFragment(
        messageId: message.id,
        fragmentIndex: i,
        totalFragments: totalFragments,
        data: fragmentData,
        timestamp: DateTime.now(),
        checksum: checksum,
      );

      fragments.add(fragment);
    }

    return fragments;
  }

  @override
  String toString() {
    return 'MessageFragment(messageId: $messageId, fragment: $fragmentIndex/$totalFragments, '
        'size: ${data.length}B, checksum: $checksum)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageFragment &&
        other.messageId == messageId &&
        other.fragmentIndex == fragmentIndex;
  }

  @override
  int get hashCode => Object.hash(messageId, fragmentIndex);
}

/// Handles reassembly of message fragments
class MessageReassembler {
  final Map<String, List<MessageFragment?>> _fragmentBuffers = {};
  final Map<String, DateTime> _fragmentTimestamps = {};

  /// Add a fragment to the reassembler
  /// Returns the complete message if all fragments are received, null otherwise
  DisasterLinkMessage? addFragment(MessageFragment fragment) {
    final messageId = fragment.messageId;

    // Initialize fragment buffer if needed
    if (!_fragmentBuffers.containsKey(messageId)) {
      _fragmentBuffers[messageId] = List.filled(fragment.totalFragments, null);
      _fragmentTimestamps[messageId] = DateTime.now();
    }

    // Verify fragment integrity
    if (!fragment.verifyIntegrity()) {
      print(
        'Fragment integrity check failed for message $messageId, fragment ${fragment.fragmentIndex}',
      );
      return null;
    }

    // Add fragment to buffer
    final buffer = _fragmentBuffers[messageId]!;
    if (fragment.fragmentIndex < buffer.length) {
      buffer[fragment.fragmentIndex] = fragment;
    }

    // Check if all fragments are received
    if (buffer.every((fragment) => fragment != null)) {
      return _reassembleMessage(messageId, buffer.cast<MessageFragment>());
    }

    return null;
  }

  /// Reassemble fragments into a complete message
  DisasterLinkMessage _reassembleMessage(
    String messageId,
    List<MessageFragment> fragments,
  ) {
    // Sort fragments by index
    fragments.sort((a, b) => a.fragmentIndex.compareTo(b.fragmentIndex));

    // Combine fragment data
    final messageData = <int>[];
    for (final fragment in fragments) {
      messageData.addAll(fragment.data);
    }

    // Clean up buffers
    _fragmentBuffers.remove(messageId);
    _fragmentTimestamps.remove(messageId);

    // Convert back to message
    return DisasterLinkMessage.fromBytes(Uint8List.fromList(messageData));
  }

  /// Clean up expired fragment buffers
  void cleanupExpiredFragments() {
    final now = DateTime.now();
    final expiredIds = <String>[];

    for (final entry in _fragmentTimestamps.entries) {
      if (now.difference(entry.value).inMilliseconds >
          BleProtocol.messageTimeout) {
        expiredIds.add(entry.key);
      }
    }

    for (final id in expiredIds) {
      _fragmentBuffers.remove(id);
      _fragmentTimestamps.remove(id);
    }
  }

  /// Get reassembly statistics
  Map<String, dynamic> getStats() {
    return {
      'activeMessages': _fragmentBuffers.length,
      'fragmentBuffers': _fragmentBuffers.map(
        (id, fragments) =>
            MapEntry(id, fragments.where((f) => f != null).length),
      ),
    };
  }
}

/// Factory class for creating common message types
class MessageFactory {
  /// Create an emergency SOS message
  static DisasterLinkMessage createEmergencySOS({
    required String senderId,
    required String senderName,
    required double latitude,
    required double longitude,
    String? additionalInfo,
  }) {
    return DisasterLinkMessage(
      id: _generateId(),
      type: MessageType.emergencySos,
      priority: MessagePriority.critical,
      senderId: senderId,
      senderName: senderName,
      payload: {
        'latitude': latitude,
        'longitude': longitude,
        'additionalInfo': additionalInfo,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
      requiresAck: true,
    );
  }

  /// Create a text message
  static DisasterLinkMessage createTextMessage({
    required String senderId,
    required String senderName,
    required String text,
    String? recipientId,
    MessagePriority priority = MessagePriority.normal,
  }) {
    return DisasterLinkMessage(
      id: _generateId(),
      type: MessageType.textMessage,
      priority: priority,
      senderId: senderId,
      senderName: senderName,
      recipientId: recipientId,
      payload: {'text': text, 'timestamp': DateTime.now().toIso8601String()},
      timestamp: DateTime.now(),
    );
  }

  /// Create a location sharing message
  static DisasterLinkMessage createLocationShare({
    required String senderId,
    required String senderName,
    required double latitude,
    required double longitude,
    String? locationName,
  }) {
    return DisasterLinkMessage(
      id: _generateId(),
      type: MessageType.locationShare,
      priority: MessagePriority.normal,
      senderId: senderId,
      senderName: senderName,
      payload: {
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
    );
  }

  /// Create a resource request message
  static DisasterLinkMessage createResourceRequest({
    required String senderId,
    required String senderName,
    required String resourceType,
    required int quantity,
    String? description,
    MessagePriority priority = MessagePriority.high,
  }) {
    return DisasterLinkMessage(
      id: _generateId(),
      type: MessageType.resourceRequest,
      priority: priority,
      senderId: senderId,
      senderName: senderName,
      payload: {
        'resourceType': resourceType,
        'quantity': quantity,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
      requiresAck: true,
    );
  }

  /// Create a status update message
  static DisasterLinkMessage createStatusUpdate({
    required String senderId,
    required String senderName,
    required String status,
    Map<String, dynamic>? additionalData,
  }) {
    return DisasterLinkMessage(
      id: _generateId(),
      type: MessageType.statusUpdate,
      priority: MessagePriority.normal,
      senderId: senderId,
      senderName: senderName,
      payload: {
        'status': status,
        'additionalData': additionalData,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
    );
  }

  /// Create an acknowledgment message
  static DisasterLinkMessage createAcknowledgment({
    required String senderId,
    required String senderName,
    required String originalMessageId,
    required String recipientId,
  }) {
    return DisasterLinkMessage(
      id: _generateId(),
      type: MessageType.acknowledgment,
      priority: MessagePriority.normal,
      senderId: senderId,
      senderName: senderName,
      recipientId: recipientId,
      payload: {
        'originalMessageId': originalMessageId,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
    );
  }

  /// Generate a unique message ID
  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
