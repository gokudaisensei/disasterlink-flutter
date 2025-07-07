import 'package:flutter/material.dart';
import '../stores/real_bluetooth_store.dart';
import '../../domain/constants/ble_constants.dart';

class RealBluetoothStatusCard extends StatelessWidget {
  final BluetoothStore store;
  final VoidCallback onToggleBluetooth;
  final VoidCallback onTogglePeripheral;

  const RealBluetoothStatusCard({
    super.key,
    required this.store,
    required this.onToggleBluetooth,
    required this.onTogglePeripheral,
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
          // Bluetooth Status
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
                      store.isBluetoothEnabled
                          ? 'Bluetooth Enabled'
                          : 'Bluetooth Disabled',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getBluetoothStatusDescription(),
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
            const SizedBox(height: 20),

            // Central Connection Status
            _buildConnectionStatusCard(
              context,
              'Central Mode',
              store.centralConnectionState,
              store.connectedDevices.length,
              Icons.bluetooth_searching,
            ),

            const SizedBox(height: 12),

            // Peripheral Status
            _buildPeripheralStatusCard(
              context,
              'Peripheral Mode',
              store.peripheralState,
              store.peripheralConnectedDevices.length,
              Icons.bluetooth_connected,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(
    BuildContext context,
    String title,
    BleConnectionState state,
    int deviceCount,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final statusColor = _getConnectionStatusColor(state);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                Text(
                  _getCentralStatusText(state, deviceCount),
                  style: textTheme.bodySmall?.copyWith(
                    color: statusColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (state == BleConnectionState.connecting)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeripheralStatusCard(
    BuildContext context,
    String title,
    BlePeripheralState state,
    int deviceCount,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final statusColor = _getPeripheralStatusColor(state);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                Text(
                  _getPeripheralStatusText(state, deviceCount),
                  style: textTheme.bodySmall?.copyWith(
                    color: statusColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: store.isPeripheralActive,
            onChanged: (_) => onTogglePeripheral(),
            activeColor: statusColor,
          ),
        ],
      ),
    );
  }

  String _getBluetoothStatusDescription() {
    if (!store.isBluetoothEnabled) {
      return 'Enable Bluetooth to start emergency mesh network';
    }

    final totalDevices = store.totalConnectedDevices;
    if (totalDevices > 0) {
      return '$totalDevices device(s) connected to emergency mesh';
    }

    return 'Ready to connect to emergency response devices';
  }

  String _getCentralStatusText(BleConnectionState state, int deviceCount) {
    switch (state) {
      case BleConnectionState.disconnected:
        return 'Not connected • Tap to scan for devices';
      case BleConnectionState.connecting:
        return 'Connecting to emergency device...';
      case BleConnectionState.connected:
        return '$deviceCount device(s) connected as central';
      case BleConnectionState.failed:
        return 'Connection failed • Check device compatibility';
      case BleConnectionState.disconnecting:
        return 'Disconnecting...';
    }
  }

  String _getPeripheralStatusText(BlePeripheralState state, int deviceCount) {
    switch (state) {
      case BlePeripheralState.stopped:
        return 'Peripheral mode disabled';
      case BlePeripheralState.starting:
        return 'Starting peripheral server...';
      case BlePeripheralState.advertising:
        return '$deviceCount device(s) connected as peripheral';
      case BlePeripheralState.failed:
        return 'Failed to start peripheral mode';
    }
  }

  Color _getConnectionStatusColor(BleConnectionState state) {
    switch (state) {
      case BleConnectionState.disconnected:
        return Colors.grey;
      case BleConnectionState.connecting:
        return Colors.orange;
      case BleConnectionState.connected:
        return Colors.green;
      case BleConnectionState.failed:
        return Colors.red;
      case BleConnectionState.disconnecting:
        return Colors.orange;
    }
  }

  Color _getPeripheralStatusColor(BlePeripheralState state) {
    switch (state) {
      case BlePeripheralState.stopped:
        return Colors.grey;
      case BlePeripheralState.starting:
        return Colors.orange;
      case BlePeripheralState.advertising:
        return Colors.green;
      case BlePeripheralState.failed:
        return Colors.red;
    }
  }
}
