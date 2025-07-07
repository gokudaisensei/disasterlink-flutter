# Quick Start Guide: DisasterLink BLE Testing

## Before You Begin

### Requirements
- 2 Android devices with BLE support (API 21+)
- Location permissions granted
- Bluetooth enabled on both devices

## Setup Instructions

### 1. Install Dependencies
```bash
cd disasterlink-flutter
flutter pub get
```

### 2. Build and Install
```bash
# For debugging/testing
flutter run

# For release testing
flutter build apk --release
```

### 3. Grant Permissions
On both devices:
- Location permission (required for BLE scanning)
- Bluetooth permissions (automatically requested)

## Quick Test Procedure

### Device A (Primary Test Device)

1. **Launch App**
   - Open DisasterLink app
   - Navigate to Bluetooth section

2. **Initialize System**
   - Tap "Initialize System"
   - Wait for "Status: Ready" indicator

3. **Start Central Mode**
   - Tap "Start Scanning"
   - Device should show "Scanning..." status

### Device B (Secondary Test Device)

1. **Launch App**
   - Open DisasterLink app
   - Navigate to Bluetooth section

2. **Initialize System**
   - Tap "Initialize System"
   - Wait for "Status: Ready" indicator

3. **Start Peripheral Mode**
   - Tap "Start Peripheral"
   - Device should show "Advertising" status

### Connection Test

1. **On Device A**
   - Wait for Device B to appear in "Discovered Devices"
   - Tap "Connect" next to Device B
   - Verify connection in "Connected Devices" section

2. **On Device B**
   - Verify Device A appears in "Peripheral Connections"
   - Check connection status shows "Connected"

### Message Test

1. **Send Simple Message**
   - On Device A, tap "Send Message" (+ button)
   - Select "Text Message" type
   - Enter: "Hello from Device A"
   - Leave recipient blank (broadcast)
   - Tap "Send"

2. **Verify Reception**
   - Check Device A "Sent Messages" shows the message
   - Check Device B "Received Messages" shows the message
   - Verify message content matches

3. **Send Large Message**
   - On Device B, tap "Send Message"
   - Select "Text Message" type
   - Enter a message over 500 characters (triggers fragmentation)
   - Send to Device A
   - Verify complete message is received correctly

### Emergency SOS Test

1. **Send SOS**
   - On either device, tap "Send Message"
   - Select "Emergency SOS" type
   - Enter: "Emergency assistance needed at location X"
   - Send as broadcast
   - Verify high priority handling (should appear at top of message list)

## Troubleshooting Quick Fixes

### Can't Find Devices
1. Ensure both devices have Bluetooth enabled
2. Grant location permissions if prompted
3. Try restarting Bluetooth on both devices
4. Check devices are within 10 meters of each other

### Connection Failed
1. Clear Bluetooth cache: Settings > Apps > Bluetooth > Storage > Clear Cache
2. Restart both apps
3. Try switching roles (Device A as peripheral, Device B as central)

### Messages Not Received
1. Check connection status on both devices
2. Try sending smaller messages first
3. Verify recipient ID is correct (or leave blank for broadcast)
4. Check message history on sending device

### Permission Errors
1. Go to Android Settings > Apps > DisasterLink > Permissions
2. Enable Location permission
3. For Android 12+, also check "Nearby devices" permission

## Expected Behavior

### Normal Operation
- **Scanning**: Should find nearby DisasterLink devices within 30 seconds
- **Connection**: Should establish connection within 10 seconds
- **Messaging**: Small messages (<500 chars) should arrive within 2-3 seconds
- **Large Messages**: May take 5-10 seconds depending on size and connection quality

### Status Indicators
- 🔴 **Red**: Error state or disconnected
- 🟡 **Yellow**: Initializing or connecting
- 🟢 **Green**: Ready and operational

### Message Priority Colors
- 🔴 **Critical**: Emergency SOS messages
- 🟠 **High**: Important communications
- 🔵 **Normal**: Regular messages
- ⚪ **Low**: Background updates

## Performance Expectations

### Connection Limits
- **Central mode**: Can connect to multiple peripherals (tested up to 5)
- **Peripheral mode**: Can accept multiple central connections (tested up to 3)

### Message Throughput
- **Small messages** (<100 chars): ~10-20 messages per minute
- **Large messages** (>1KB): ~2-5 messages per minute
- **Fragmented messages**: Automatic handling, may take longer

### Range
- **Optimal**: 1-5 meters (indoor)
- **Maximum**: Up to 10 meters (line of sight)
- **Factors**: Walls, interference, device antenna quality

## Common Test Scenarios

### Scenario 1: Basic P2P Communication
1. Two users need to communicate without internet
2. Both open app, initialize BLE
3. One starts peripheral, other scans and connects
4. Exchange text messages bidirectionally

### Scenario 2: Emergency Broadcast
1. User in emergency situation
2. Sends SOS message with location
3. All nearby DisasterLink devices receive alert
4. Recipients can respond with assistance offers

### Scenario 3: Group Coordination
1. Multiple devices in area (3-5 devices)
2. One device acts as coordinator (central connecting to multiple peripherals)
3. Coordinator relays messages between all devices
4. Enables group communication

### Scenario 4: Network Resilience
1. Establish connections between devices
2. Simulate interference (move devices apart)
3. Verify automatic reconnection
4. Test message queuing during disconnection

## Development Testing

### Debug Mode
```bash
# Run with detailed logging
flutter run --debug
```

### Log Monitoring
```bash
# Android logs
adb logcat | grep -E "(BleGattServer|DisasterLink|BLE)"

# Flutter logs
flutter logs
```

### Performance Profiling
```bash
# Profile memory usage
flutter run --profile

# Analyze performance
flutter run --trace-startup
```

## Next Steps

After successful basic testing:

1. **Read Full Documentation**: `BLE_PROTOCOL_DOCUMENTATION.md`
2. **Stress Testing**: Try with multiple devices and heavy message loads
3. **Range Testing**: Test maximum distance capabilities
4. **Integration Testing**: Test with other app features (location, mapping)
5. **User Experience Testing**: Get feedback on UI/UX from actual users

## Support

If you encounter issues:
1. Check this troubleshooting guide first
2. Review full documentation
3. Check device logs for detailed error information
4. Test with different device combinations
5. Report issues with detailed steps to reproduce

Remember: BLE is sensitive to environmental factors. If testing doesn't work immediately, try different locations, ensure proper permissions, and verify device compatibility.
