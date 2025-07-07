# DisasterLink BLE P2P Messaging Protocol Documentation

## Table of Contents
1. [Overview](#overview)
2. [Protocol Specification](#protocol-specification)
3. [Message Fragmentation](#message-fragmentation)
4. [Implementation Architecture](#implementation-architecture)
5. [Testing Instructions](#testing-instructions)
6. [API Reference](#api-reference)
7. [Troubleshooting](#troubleshooting)

## Overview

The DisasterLink BLE P2P Messaging System provides a robust, offline communication protocol for emergency situations using Bluetooth Low Energy (BLE). The system supports both central (client) and peripheral (server) roles, enabling mesh-like communication networks without infrastructure.

### Key Features
- **Dual-role operation**: Each device can act as both central and peripheral
- **Message fragmentation**: Supports large messages up to 8KB with automatic fragmentation
- **UTF-8 JSON encoding**: Structured message format with metadata
- **Emergency prioritization**: Priority-based message handling
- **Automatic reassembly**: Fragments are automatically reassembled into complete messages
- **Connection management**: Robust connection handling with retry logic
- **Real-time UI updates**: Live status updates and message history

## Protocol Specification

### BLE Service and Characteristics

#### Service UUID
```
b32b86a1-a04c-4db3-8276-b17ec127dab1
```

#### Characteristics

1. **Write Characteristic** (`25c54c03-9f43-4015-ba94-c923cbfd7a4b`)
   - **Properties**: WRITE, WRITE_WITHOUT_RESPONSE
   - **Purpose**: Central writes message fragments to peripheral
   - **Max size**: 512 bytes

2. **Notify Characteristic** (`c7911626-4838-4781-aae8-a5e6ea601ed2`)
   - **Properties**: NOTIFY, READ
   - **Purpose**: Peripheral sends message fragments to central
   - **Max size**: 512 bytes

3. **Read Characteristic** (`d10fe796-9f87-43ab-ba06-00530ebee963`)
   - **Properties**: READ
   - **Purpose**: Central can read the latest complete message
   - **Max size**: Variable (complete message)

### Message Types

The protocol supports several message types for different emergency scenarios:

```dart
enum MessageType {
  emergencySos,      // Critical emergency broadcasts
  textMessage,       // General text communication
  locationShare,     // GPS coordinates sharing
  resourceRequest,   // Request for specific resources
  statusUpdate,      // General status updates
  acknowledgment,    // System acknowledgments
  heartbeat,         // Keep-alive messages
}
```

### Priority Levels

```dart
enum MessagePriority {
  critical(0),  // Emergency SOS messages
  high(1),      // Important communications
  normal(2),    // Regular messages
  low(3),       // Background updates
}
```

## Message Fragmentation

### Fragment Structure

Each fragment contains a 12-byte header followed by payload data:

```
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| Message ID (16 bytes UUID)                        |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| Total Size (4 bytes)      | Fragment Index (4 bytes)|
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| Total Fragments (4 bytes)                         |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| Payload Data (max 500 bytes)                      |
| ...                                                |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
```

### Fragmentation Algorithm

1. **Size Check**: Messages larger than 500 bytes are fragmented
2. **Fragment Creation**: Message is split into chunks of 500 bytes
3. **Header Addition**: Each fragment gets a 12-byte header
4. **Sequential Transmission**: Fragments are sent in order
5. **Reassembly**: Receiver collects fragments and rebuilds the original message

### Message Format

Complete messages use JSON structure:

```json
{
  "id": "uuid-string",
  "type": "emergency_sos",
  "priority": 0,
  "senderId": "device-uuid",
  "senderName": "Device Name",
  "recipientId": null,
  "payload": {
    "message": "Emergency assistance needed",
    "location": {
      "latitude": 37.7749,
      "longitude": -122.4194
    },
    "timestamp": "2024-01-15T10:30:00Z"
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "ttl": 3600,
  "requiresAck": true,
  "hopCount": 0
}
```

## Implementation Architecture

### Components Overview

#### Flutter/Dart Layer
- **BluetoothStore**: Main state management for BLE operations
- **BleCentralService**: Handles central role operations (scanning, connecting)
- **BlePeripheralService**: Dart API for peripheral operations via method channels
- **Message Models**: Data structures for messages and fragments
- **UI Components**: Real-time displays for status, devices, and messages

#### Native Android Layer
- **BleGattServer.kt**: Native BLE GATT server implementation
- **MainActivity.kt**: Method channel integration

### Central Role Implementation

The central role uses `flutter_blue_plus` for:
- **Device scanning** with service UUID filtering
- **Connection management** with automatic retry
- **Characteristic discovery** and setup
- **Message transmission** with fragmentation
- **Notification handling** for incoming messages

### Peripheral Role Implementation

The peripheral role uses native Android BLE APIs:
- **GATT server setup** with custom service
- **Advertisement** broadcasting device availability
- **Connection handling** for multiple clients
- **Characteristic read/write operations**
- **Message reassembly** from fragments

## Testing Instructions

### Prerequisites

1. **Two Android devices** with BLE support (API 21+)
2. **Location permissions** granted
3. **Bluetooth enabled** on both devices
4. **App installed** on both devices

### Basic Functionality Test

#### Device A (Central Role)
1. Launch the app and navigate to Bluetooth section
2. Tap "Initialize System" to start BLE services
3. Verify "Bluetooth Status" shows "Connected"
4. Tap "Start Scanning" to discover nearby devices
5. Wait for Device B to appear in "Discovered Devices"
6. Tap "Connect" next to Device B
7. Verify connection in "Connected Devices" section

#### Device B (Peripheral Role)
1. Launch the app and navigate to Bluetooth section
2. Tap "Initialize System" to start BLE services
3. Tap "Start Peripheral" to begin advertising
4. Verify "Peripheral Status" shows "Advertising"
5. Wait for Device A to connect
6. Verify connection in "Peripheral Connections"

### Message Exchange Test

#### Sending Messages
1. On Device A, tap the "Send Message" button
2. Select message type (e.g., "Emergency SOS")
3. Enter message content
4. Select Device B as recipient (or leave blank for broadcast)
5. Tap "Send"
6. Verify message appears in "Sent Messages" on Device A
7. Verify message appears in "Received Messages" on Device B

#### Large Message Test
1. Send a message larger than 500 characters
2. Verify automatic fragmentation occurs
3. Check that the complete message is reassembled correctly
4. Monitor the "Connection Stats" for fragmentation details

### Error Scenarios

#### Connection Loss Test
1. Establish connection between devices
2. Turn off Bluetooth on one device
3. Verify automatic reconnection attempts
4. Re-enable Bluetooth and verify reconnection

#### Permissions Test
1. Revoke location permissions
2. Attempt to start scanning
3. Verify proper error handling and permission requests

### Performance Test

#### Multiple Connections
1. Set up Device A as central
2. Connect multiple peripheral devices (if available)
3. Send messages to different devices
4. Verify proper message routing

#### Stress Test
1. Send multiple large messages rapidly
2. Monitor memory usage and performance
3. Verify all messages are delivered correctly

### Log Analysis

Check device logs for detailed BLE operations:

```bash
# Android logs
adb logcat | grep -E "(BleGattServer|BluetoothStore|BLE)"

# Flutter logs
flutter logs
```

## API Reference

### BluetoothStore Methods

#### Initialization
```dart
// Initialize BLE services
await bluetoothStore.initialize();

// Check if system is ready
bool isReady = bluetoothStore.isInitialized;
```

#### Central Operations
```dart
// Start scanning for devices
await bluetoothStore.startScanning();

// Connect to a device
await bluetoothStore.connectToDevice(device);

// Disconnect from device
await bluetoothStore.disconnectFromDevice(deviceId);
```

#### Peripheral Operations
```dart
// Start advertising as peripheral
await bluetoothStore.startPeripheral();

// Stop peripheral mode
await bluetoothStore.stopPeripheral();
```

#### Messaging
```dart
// Send a message
DisasterLinkMessage message = DisasterLinkMessage(
  id: uuid.v4(),
  type: MessageType.emergencySos,
  priority: MessagePriority.critical,
  senderId: deviceId,
  senderName: deviceName,
  payload: {"message": "Help needed!"},
  timestamp: DateTime.now(),
);

await bluetoothStore.sendMessage(message, recipientId);
```

#### State Monitoring
```dart
// Listen to state changes
bluetoothStore.addListener(() {
  // React to state changes
  print('BLE State: ${bluetoothStore.isBluetoothEnabled}');
  print('Connected devices: ${bluetoothStore.connectedDevices.length}');
});

// Access current state
List<BluetoothDevice> devices = bluetoothStore.discoveredDevices;
List<DisasterLinkMessage> messages = bluetoothStore.receivedMessages;
```

### Message Creation Helper

```dart
// Create emergency SOS message
DisasterLinkMessage createSOSMessage(String deviceId, String deviceName, String message, {Position? location}) {
  Map<String, dynamic> payload = {"message": message};
  
  if (location != null) {
    payload["location"] = {
      "latitude": location.latitude,
      "longitude": location.longitude,
      "accuracy": location.accuracy,
    };
  }
  
  return DisasterLinkMessage(
    id: const Uuid().v4(),
    type: MessageType.emergencySos,
    priority: MessagePriority.critical,
    senderId: deviceId,
    senderName: deviceName,
    payload: payload,
    timestamp: DateTime.now(),
    requiresAck: true,
  );
}
```

## Troubleshooting

### Common Issues

#### BLE Not Available
**Problem**: "Bluetooth not supported" error
**Solution**: 
- Verify device has BLE hardware
- Check AndroidManifest.xml for required features
- Ensure minimum API level 21

#### Permission Denied
**Problem**: Location permission errors
**Solution**:
- Grant location permissions in app settings
- For Android 12+, ensure BLUETOOTH_SCAN and BLUETOOTH_ADVERTISE permissions
- Request permissions at runtime

#### Connection Failures
**Problem**: Unable to connect to devices
**Solution**:
- Verify both devices are in range (typically <10 meters)
- Restart Bluetooth on both devices
- Clear Bluetooth cache in Android settings
- Check for interference from other BLE devices

#### Message Fragmentation Issues
**Problem**: Large messages not received completely
**Solution**:
- Check MTU negotiation in logs
- Verify fragment reassembly timeout settings
- Monitor connection stability during transmission

#### Performance Issues
**Problem**: Slow scanning or connection
**Solution**:
- Reduce scan interval in BleCentralService
- Limit concurrent connections
- Optimize message payload size
- Use background processing for large operations

### Debug Information

#### Enable Verbose Logging
Add to main.dart:
```dart
void main() {
  // Enable BLE debugging
  FlutterBluePlus.setLogLevel(LogLevel.verbose);
  
  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}
```

#### Monitor BLE State
```dart
// Stream BLE adapter state
FlutterBluePlus.adapterState.listen((state) {
  print('BLE Adapter State: $state');
});

// Stream scan results
FlutterBluePlus.scanResults.listen((results) {
  print('Scan Results: ${results.length} devices found');
});
```

### Performance Optimization

#### Memory Management
- Dispose streams and subscriptions properly
- Limit message history size
- Use efficient data structures for device management

#### Battery Optimization
- Implement adaptive scanning intervals
- Use connection intervals appropriate for use case
- Minimize advertising power consumption

#### Network Efficiency
- Compress large payloads before fragmentation
- Implement message deduplication
- Use acknowledgments for critical messages only

## Security Considerations

### Data Protection
- All messages are transmitted in plain text (BLE limitation)
- Consider adding application-level encryption for sensitive data
- Implement message expiration (TTL) for security

### Access Control
- BLE connections are inherently peer-to-peer
- Implement application-level authentication if needed
- Consider device whitelisting for restricted networks

### Privacy
- Device names and IDs are visible to all nearby devices
- Consider using rotating identifiers for enhanced privacy
- Implement user consent for location sharing

## Future Enhancements

### Planned Features
1. **Message Encryption**: End-to-end encryption for sensitive communications
2. **Mesh Networking**: Multi-hop message relay through intermediate devices
3. **QoS Implementation**: Quality of service guarantees for critical messages
4. **Offline Mapping**: Integration with offline maps for location-based services
5. **Voice Messages**: Audio message support with compression
6. **File Transfer**: Support for transferring small files and images

### Protocol Extensions
1. **Acknowledgment System**: Reliable message delivery confirmation
2. **Message Routing**: Intelligent routing in mesh networks
3. **Device Discovery**: Enhanced device capability advertisement
4. **Synchronization**: Clock sync and message ordering
5. **Bandwidth Management**: Dynamic adaptation to network conditions

This documentation provides a comprehensive guide to understanding, implementing, and testing the DisasterLink BLE P2P messaging system. For additional support or feature requests, refer to the project repository and issue tracker.
