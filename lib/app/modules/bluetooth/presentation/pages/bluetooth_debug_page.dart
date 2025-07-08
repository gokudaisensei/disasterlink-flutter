import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../stores/real_bluetooth_store.dart';
import '../../utils/bluetooth_debug.dart';

class BluetoothDebugPage extends StatefulWidget {
  const BluetoothDebugPage({super.key});

  @override
  State<BluetoothDebugPage> createState() => _BluetoothDebugPageState();
}

class _BluetoothDebugPageState extends State<BluetoothDebugPage> {
  final TextEditingController _messageController = TextEditingController();
  final BluetoothStore _store = Modular.get<BluetoothStore>();
  final BluetoothDebug _debug = BluetoothDebug(Modular.get<BluetoothStore>());

  String _debugOutput = '';
  bool _runningTest = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _messageController.text = "Test message from DisasterLink";
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _updateConnectionStatus();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateConnectionStatus();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _updateConnectionStatus() {
    if (!mounted) return;
    setState(() {});
  }

  void _runDiagnostics() {
    final output = StringBuffer();

    // Redirect print output to our buffer
    final originalPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        output.writeln(message);
      }
    };

    // Run diagnostics
    _debug.runCompleteDebug();

    // Restore print function
    debugPrint = originalPrint;

    // Update UI
    setState(() {
      _debugOutput = output.toString();
    });
  }

  Future<void> _sendTestMessage() async {
    if (_messageController.text.isEmpty || _runningTest) return;

    setState(() {
      _runningTest = true;
      _debugOutput = 'Sending test message: ${_messageController.text}\n';
    });

    try {
      final message = _messageController.text;

      // Send the message and record start time
      final startTime = DateTime.now();
      _debugOutput += 'Start time: ${startTime.toString()}\n';

      await _store.sendTextMessage(text: message);

      _debugOutput += 'Message sent at ${DateTime.now().toString()}\n';
      _debugOutput += 'Checking for acknowledgments...\n';

      // Wait and check for acknowledgments
      for (int i = 0; i < 5; i++) {
        await Future.delayed(Duration(seconds: 1));

        // Get the most recent message sent
        final sentMessages = _store.sentMessages;
        if (sentMessages.isEmpty) {
          _debugOutput += 'No sent messages found!\n';
          break;
        }

        final lastMessage = sentMessages.last;
        final messageId = lastMessage.id;

        _debugOutput +=
            'Checking for acknowledgments for message $messageId (${i + 1}s)...\n';

        // Check for acknowledgments
        final receivedAcks = _store.receivedMessages
            .where(
              (msg) =>
                  msg.type.value == 'acknowledgment' &&
                  msg.payload['originalMessageId'] == messageId,
            )
            .length;

        if (receivedAcks > 0) {
          _debugOutput +=
              'SUCCESS! Received $receivedAcks acknowledgment(s).\n';
          break;
        }
      }

      // Final report
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      _debugOutput += 'Test completed in ${elapsed}ms\n';
      _debugOutput += '\n=== FINAL STATUS ===\n';

      // Get connection status
      _debugOutput += 'Connected Devices: ${_store.totalConnectedDevices}\n';
      _debugOutput +=
          'Central: ${_store.connectedDevices.length}, Peripheral: ${_store.peripheralConnectedDevices.length}\n';

      // Get diagnostics
      _runDiagnostics();
    } catch (e) {
      setState(() {
        _debugOutput += 'ERROR: $e\n';
      });
    } finally {
      setState(() {
        _runningTest = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Bluetooth Enabled: ${_store.isBluetoothEnabled}'),
                    Text('Connected Devices: ${_store.totalConnectedDevices}'),
                    Text('Central State: ${_store.centralConnectionState}'),
                    Text('Peripheral State: ${_store.peripheralState}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Test Message Sending',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Test Message',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _runningTest ? null : _sendTestMessage,
                    child: Text(
                      _runningTest ? 'Sending...' : 'Send Test Message',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _runDiagnostics,
                    child: const Text('Run Diagnostics'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Debug Output',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _debugOutput.isEmpty
                                ? 'No debug output yet'
                                : _debugOutput,
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
