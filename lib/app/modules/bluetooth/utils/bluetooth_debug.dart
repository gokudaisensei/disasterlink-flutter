import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../presentation/stores/real_bluetooth_store.dart';

/// Bluetooth Debug Utility
///
/// This utility provides simple functions to help debug Bluetooth connectivity
/// and message transmission issues in the DisasterLink app.
class BluetoothDebug {
  final BluetoothStore store;

  BluetoothDebug(this.store);

  /// Run basic diagnostics
  void runDiagnostics() {
    print('\n=== BLUETOOTH DIAGNOSTICS ===');

    // Print connection stats
    final connStats = store.getConnectionStats();
    print('\n=== CONNECTION STATS ===');
    connStats.forEach((key, value) {
      print('$key: $value');
    });

    // Print message stats
    final messageStats = store.getMessageStats();
    print('\n=== MESSAGE STATS ===');
    messageStats.forEach((key, value) {
      print('$key: $value');
    });

    // Check hardware status
    _checkHardwareStatus();

    // Analyze recent message performance
    store.debugAnalyzeMessagePerformance();

    print('\n=== END DIAGNOSTICS ===\n');
  }

  /// Check hardware status
  Future<void> _checkHardwareStatus() async {
    print('\n=== HARDWARE STATUS ===');

    try {
      final isOn = await FlutterBluePlus.isOn;
      print('Bluetooth Adapter: ${isOn ? "ON" : "OFF"}');
    } catch (e) {
      print('Error checking Bluetooth status: $e');
    }

    try {
      final state = await FlutterBluePlus.adapterState.first;
      print('Adapter State: $state');
    } catch (e) {
      print('Error checking adapter state: $e');
    }

    try {
      final devices = FlutterBluePlus.connectedDevices;
      print('Connected Device Count: ${devices.length}');

      for (final device in devices) {
        print('- ${device.remoteId.str} (${device.platformName})');
      }
    } catch (e) {
      print('Error checking connected devices: $e');
    }
  }

  /// Check recent messages
  void checkRecentMessages() {
    print('\n=== RECENT MESSAGES ===');

    final sentMessages = store.sentMessages;
    final receivedMessages = store.receivedMessages;

    print('Recent Sent (${sentMessages.length}):');
    final recentSent = sentMessages.length > 5
        ? sentMessages.sublist(sentMessages.length - 5)
        : sentMessages;

    for (final msg in recentSent) {
      final timeDiff = DateTime.now().difference(msg.timestamp).inSeconds;
      print('- ID: ${msg.id}, Type: ${msg.type.value}, Age: ${timeDiff}s');
    }

    print('Recent Received (${receivedMessages.length}):');
    final recentReceived = receivedMessages.length > 5
        ? receivedMessages.sublist(receivedMessages.length - 5)
        : receivedMessages;

    for (final msg in recentReceived) {
      final timeDiff = DateTime.now().difference(msg.timestamp).inSeconds;
      print('- ID: ${msg.id}, Type: ${msg.type.value}, Age: ${timeDiff}s');
    }
  }

  /// Check connection details
  void checkConnectionDetails() {
    print('\n=== CONNECTION DETAILS ===');

    final connectedDevices = store.connectedDevices;
    print('Connected Central Devices: ${connectedDevices.length}');

    for (final device in connectedDevices) {
      print('- ${device.remoteId.str} (${device.platformName})');
    }

    final peripheralConnections = store.peripheralConnectedDevices;
    print('Peripheral Connections: ${peripheralConnections.length}');

    for (final device in peripheralConnections) {
      print('- ${device['deviceId']} (${device['deviceName'] ?? 'Unknown'})');
    }
  }

  /// Run a complete debug check
  void runCompleteDebug() async {
    print('\n======= DISASTER LINK BLUETOOTH DEBUG =======');
    print('Running complete debug at ${DateTime.now()}');

    await _checkHardwareStatus();
    checkConnectionDetails();
    checkRecentMessages();
    store.debugAnalyzeMessagePerformance();

    // Check for pending acknowledgments
    final sentWithAck = store.sentMessages
        .where((msg) => msg.requiresAck)
        .toList();
    final receivedAcks = store.receivedMessages
        .where((msg) => msg.type.value == 'acknowledgment')
        .toList();

    print('\n=== ACKNOWLEDGMENT STATUS ===');
    print('Messages requiring ACK: ${sentWithAck.length}');
    print('ACKs received: ${receivedAcks.length}');

    // Find messages without acknowledgments
    final pendingAcks = sentWithAck.where((msg) {
      return !receivedAcks.any(
        (ack) => ack.payload['originalMessageId'] == msg.id,
      );
    }).toList();

    print('Pending acknowledgments: ${pendingAcks.length}');

    for (final msg in pendingAcks.take(5)) {
      final age = DateTime.now().difference(msg.timestamp).inSeconds;
      print('- ID: ${msg.id}, Type: ${msg.type.value}, Age: ${age}s');
    }

    print('\n======= END DEBUG REPORT =======');
  }
}
