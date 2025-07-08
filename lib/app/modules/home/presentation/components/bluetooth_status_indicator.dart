import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// A simple widget to display the Bluetooth connection status
class BluetoothStatusIndicator extends StatefulWidget {
  const BluetoothStatusIndicator({super.key});

  @override
  State<BluetoothStatusIndicator> createState() =>
      _BluetoothStatusIndicatorState();
}

class _BluetoothStatusIndicatorState extends State<BluetoothStatusIndicator> {
  dynamic _bluetoothStore;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    // Try to get the store if it exists
    try {
      _bluetoothStore = Modular.get<Object>(key: 'BluetoothStore');
      _bluetoothStore!.addListener(_onStoreChanged);
      _updateStatus();
    } catch (e) {
      // Store not available yet, will show inactive status
    }
  }

  void _onStoreChanged() {
    if (mounted) {
      _updateStatus();
    }
  }

  void _updateStatus() {
    final isInitialized = _bluetoothStore?.isInitialized ?? false;
    final isEnabled = _bluetoothStore?.isBluetoothEnabled ?? false;

    setState(() {
      _isActive = isInitialized && isEnabled;
    });
  }

  @override
  void dispose() {
    _bluetoothStore?.removeListener(_onStoreChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Text(
          _isActive ? 'Mesh active' : 'Mesh inactive',
          style: textTheme.bodySmall?.copyWith(
            color: _isActive ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          _isActive ? Icons.language : Icons.language_outlined,
          color: _isActive ? Colors.green : Colors.orange,
          size: 16,
        ),
      ],
    );
  }
}
