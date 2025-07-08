# Bluetooth Debugging Functions

This document explains the new debugging functions added to the DisasterLink Bluetooth module to help with development, testing, and troubleshooting.

## Overview

We've added comprehensive debugging functions to track and analyze Bluetooth message sending and receiving in the DisasterLink app. These functions provide detailed logs about message transmission, content, and performance metrics.

## Debug Functions

### 1. Message Sending Debug

`debugLogMessageSend(DisasterLinkMessage message, BluetoothDevice? targetDevice)`

This function logs detailed information when a message is being sent:
- Message ID
- Message type
- Sender information
- Content summary
- Target information
- Message size estimate

### 2. Message Receiving Debug

`debugLogMessageReceive(DisasterLinkMessage message, String source)`

This function logs detailed information when a message is received:
- Message ID
- Message type
- Sender information
- Content summary
- Source (central or peripheral)
- Receipt timestamp
- Additional type-specific details

### 3. Performance Analysis

`debugAnalyzeMessagePerformance()`

This function provides analysis of messaging performance:
- Total sent/received messages
- Distribution by message type
- Success rates for acknowledgments

## How to Use

The debugging functions are automatically integrated into the message sending and receiving flow. You'll see debug output in the console when:

1. Sending any message (text, emergency SOS, location share)
2. Receiving any message from other devices
3. After acknowledgment messages are processed

### Example Debug Output

```
DEBUG_SEND [2025-07-07T14:30:45.123Z] Message abc123:
  Type: text
  Sender: DisasterLink-123456 (123456789)
  Payload: {text: Hello world}
  Target: as broadcast
  Size: 85 bytes

DEBUG_RECEIVE [2025-07-07T14:30:45.789Z] Message xyz789:
  Type: emergencySos
  Sender: DisasterLink-654321 (987654321)
  Payload: {location: {latitude: 34.5678, longitude: -118.1234}}
  Source: peripheral
  Receipt Time: 2025-07-07T14:30:45.789Z
  Location: lat=34.5678, lng=-118.1234

DEBUG_PERFORMANCE ANALYSIS:
  Total Sent: 5
  Total Received: 3
  Sent by type: text:2, emergencySos:1, locationShare:2
  Received by type: text:1, emergencySos:1, acknowledgment:1
  Acknowledgment rate: 33.3%
```

## Testing

You can use the included `test_bluetooth_debug.dart` script to generate test messages and see the debugging functions in action:

```bash
flutter run test_bluetooth_debug.dart
```

This will send test messages of each type and display the debug logs in the console.

## Use Cases

1. **Development**: Understand message flow and detect issues
2. **Testing**: Verify message transmission and receipt
3. **Troubleshooting**: Diagnose connection or transmission problems
4. **Performance Analysis**: Evaluate message delivery rates and timing
