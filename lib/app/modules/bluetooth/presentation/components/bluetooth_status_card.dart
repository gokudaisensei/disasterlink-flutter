import 'package:flutter/material.dart';
import '../stores/bluetooth_store.dart';

class BluetoothStatusCard extends StatelessWidget {
  final BluetoothStore store;
  final VoidCallback onToggleBluetooth;

  const BluetoothStatusCard({
    super.key,
    required this.store,
    required this.onToggleBluetooth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: store.isBluetoothEnabled
                      ? colorScheme.primary.withOpacity(0.1)
                      : colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  store.isBluetoothEnabled
                      ? Icons.bluetooth
                      : Icons.bluetooth_disabled,
                  color: store.isBluetoothEnabled
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.isBluetoothEnabled ? 'Bluetooth Enabled' : 'Bluetooth Disabled',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusDescription(),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: store.isBluetoothEnabled,
                onChanged: (_) => onToggleBluetooth(),
                activeColor: colorScheme.primary,
              ),
            ],
          ),
          if (store.isBluetoothEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getConnectionStatusColor(colorScheme).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getConnectionStatusColor(colorScheme).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getConnectionStatusColor(colorScheme),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getConnectionStatusText(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: _getConnectionStatusColor(colorScheme),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (store.status == BluetoothConnectionStatus.connecting)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          _getConnectionStatusColor(colorScheme),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusDescription() {
    if (!store.isBluetoothEnabled) {
      return 'Enable Bluetooth to connect to emergency mesh network';
    }
    
    switch (store.status) {
      case BluetoothConnectionStatus.disconnected:
        return 'Ready to connect to emergency devices';
      case BluetoothConnectionStatus.connecting:
        return 'Establishing secure connection...';
      case BluetoothConnectionStatus.connected:
        return '${store.connectedDevices.length} device(s) connected to mesh';
      case BluetoothConnectionStatus.error:
        return 'Connection issue - check device compatibility';
    }
  }

  String _getConnectionStatusText() {
    switch (store.status) {
      case BluetoothConnectionStatus.disconnected:
        return 'Not connected to mesh network';
      case BluetoothConnectionStatus.connecting:
        return 'Connecting to emergency mesh...';
      case BluetoothConnectionStatus.connected:
        return 'Connected to emergency mesh network';
      case BluetoothConnectionStatus.error:
        return 'Connection failed';
    }
  }

  Color _getConnectionStatusColor(ColorScheme colorScheme) {
    switch (store.status) {
      case BluetoothConnectionStatus.disconnected:
        return colorScheme.outline;
      case BluetoothConnectionStatus.connecting:
        return colorScheme.primary;
      case BluetoothConnectionStatus.connected:
        return Colors.green;
      case BluetoothConnectionStatus.error:
        return Colors.red;
    }
  }
}
