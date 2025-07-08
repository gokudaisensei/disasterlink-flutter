# Bluetooth Debugging Guide for DisasterLink

This document explains how to use the built-in debugging tools to diagnose Bluetooth connectivity and message delivery issues in the DisasterLink app.

## Accessing the Debug Tools

1. Navigate to the Bluetooth page in the app
2. Add `/debug` to the route to access the debug page
   - For example: `/bluetooth/debug`
   - Or navigate to `/bluetooth` and then click on the "Debug" button (if available)

## Using the Debug Interface

The debug interface provides several tools to help diagnose Bluetooth issues:

### Connection Status

This section shows the current state of Bluetooth connections:
- Whether Bluetooth is enabled
- Number of connected devices
- Central connection state
- Peripheral state

### Test Message Sending

Use this section to test message delivery:
1. Enter a test message in the text field
2. Click "Send Test Message"
3. The debug output will show the progress of the message delivery
4. The test will check for acknowledgments from other devices

### Diagnostics

Click "Run Diagnostics" to perform a complete analysis of the Bluetooth system:
- Hardware status (Bluetooth adapter state)
- Connected devices
- Recent messages (sent and received)
- Acknowledgment status

## Command Line Debugging

You can also use the Flutter console output to debug Bluetooth issues. Look for the following debug tags:

- `DEBUG_SEND`: Details about sent messages
- `DEBUG_RECEIVE`: Information about received messages
- `DEBUG_PERFORMANCE`: Message transmission statistics
- `DEBUG_TRACK`: Message delivery tracking
- `DEBUG_MESSAGE_TRACKING`: Detailed message tracking

## Common Issues and Solutions

### Messages Sent But Not Acknowledged

If messages are being sent but not acknowledged:

1. Check if the other device is connected (see Connection Status)
2. Verify that both devices have the DisasterLink app open
3. Check if Bluetooth is enabled on both devices
4. Try restarting the Bluetooth service (toggle Bluetooth off/on)
5. Run diagnostics to get more details about the message delivery

### No Devices Connecting

If devices are not connecting:

1. Make sure Bluetooth is enabled on both devices
2. Verify that devices are in close proximity
3. Check if location services are enabled (required for Bluetooth scanning on Android)
4. Try restarting the app on both devices

## Advanced Debugging

For more advanced debugging, use the Flutter logs from the terminal:

```
flutter logs
```

This will show more detailed information about Bluetooth operations including:

- Device scanning
- Connection attempts
- Service discovery
- Characteristic operations
- Error messages

## Reporting Issues

When reporting Bluetooth-related issues, please include:

1. The output from the "Run Diagnostics" tool
2. Steps to reproduce the issue
3. Device models and OS versions involved
4. Any error messages shown in the debug output
