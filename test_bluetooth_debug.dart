// Test script to demonstrate debug functions for bluetooth messages
// This file can be run using 'flutter run test_bluetooth_debug.dart'

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'lib/app/modules/bluetooth/presentation/stores/real_bluetooth_store.dart';
import 'lib/app/modules/bluetooth/domain/models/message_models.dart';
import 'lib/app/app_module.dart';

void main() {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Create and initialize ModularApp
  final app = ModularApp(
    module: AppModule(),
    child: const MaterialApp(home: TestDebugPage()),
  );

  // Run the app
  runApp(app);
}

class TestDebugPage extends StatefulWidget {
  const TestDebugPage({super.key});

  @override
  State<TestDebugPage> createState() => _TestDebugPageState();
}

class _TestDebugPageState extends State<TestDebugPage> {
  late BluetoothStore _bluetoothStore;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Get BluetoothStore instance and initialize
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _bluetoothStore = Modular.get<BluetoothStore>();
      await _bluetoothStore.initialize();

      setState(() {
        _isInitialized = true;
      });

      // Wait for initialization
      await Future.delayed(const Duration(seconds: 3));

      // Send test messages
      await _sendTestMessages();
    });
  }

  Future<void> _sendTestMessages() async {
    // Send a text message
    await _bluetoothStore.sendTextMessage(
      text: "Test debug message from DisasterLink",
    );

    // Wait between messages
    await Future.delayed(const Duration(seconds: 2));

    // Send an emergency SOS message
    await _bluetoothStore.sendEmergencySOS(
      additionalInfo: "This is a test emergency message",
    );

    // Wait between messages
    await Future.delayed(const Duration(seconds: 2));

    // Send a location share message
    await _bluetoothStore.sendLocationShare(locationName: "Test Location");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Debug Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isInitialized
                  ? 'Bluetooth initialized and running'
                  : 'Initializing Bluetooth...',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isInitialized ? _sendTestMessages : null,
              child: const Text('Send Test Messages'),
            ),
          ],
        ),
      ),
    );
  }
}
