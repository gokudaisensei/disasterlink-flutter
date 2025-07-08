import 'package:flutter/material.dart';
import '../stores/real_bluetooth_store.dart';
import 'message_history_section.dart';

class MessagesTab extends StatelessWidget {
  final BluetoothStore bluetoothStore;

  const MessagesTab({super.key, required this.bluetoothStore});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: MessageHistorySection(
        messages: [
          ...bluetoothStore.receivedMessages,
          ...bluetoothStore.sentMessages,
        ],
      ),
    );
  }
}
