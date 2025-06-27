import 'package:flutter/material.dart';
import '../stores/bluetooth_store.dart';

class ConnectionStats extends StatelessWidget {
  final BluetoothStore store;

  const ConnectionStats({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network Statistics',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                context,
                'Connected',
                '${store.connectedDevices.length}',
                Icons.link,
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Available',
                '${store.availableDevices.length}',
                Icons.bluetooth_searching,
                colorScheme.primary,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Network Range',
                _getNetworkRange(),
                Icons.wifi_tethering,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                context,
                'Signal Quality',
                _getAverageSignal(),
                Icons.signal_cellular_alt,
                _getSignalColor(),
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Mesh Hops',
                '${_getMeshHops()}',
                Icons.hub,
                Colors.purple,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Uptime',
                _getUptime(),
                Icons.timer,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getNetworkRange() {
    if (store.connectedDevices.isEmpty) return '0m';
    return '~100m';
  }

  String _getAverageSignal() {
    if (store.connectedDevices.isEmpty) return '0%';
    
    final totalSignal = store.connectedDevices
        .map((device) => device.signalStrength)
        .reduce((a, b) => a + b);
    final average = (totalSignal / store.connectedDevices.length).round();
    return '$average%';
  }

  Color _getSignalColor() {
    if (store.connectedDevices.isEmpty) return Colors.grey;
    
    final totalSignal = store.connectedDevices
        .map((device) => device.signalStrength)
        .reduce((a, b) => a + b);
    final average = totalSignal / store.connectedDevices.length;
    
    if (average >= 80) return Colors.green;
    if (average >= 60) return Colors.orange;
    return Colors.red;
  }

  int _getMeshHops() {
    if (store.connectedDevices.isEmpty) return 0;
    return store.connectedDevices.length > 2 ? 2 : 1;
  }

  String _getUptime() {
    if (store.connectedDevices.isEmpty) return '0m';
    return '${DateTime.now().minute}m';
  }
}
