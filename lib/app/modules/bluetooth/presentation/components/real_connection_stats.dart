import 'package:flutter/material.dart';
import '../stores/real_bluetooth_store.dart';

class RealConnectionStats extends StatelessWidget {
  final BluetoothStore store;

  const RealConnectionStats({super.key, required this.store});

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
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                context,
                'Total Devices',
                '${store.totalConnectedDevices}',
                Icons.devices,
                _getConnectionColor(store.totalConnectedDevices),
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Discovered',
                '${store.discoveredDevices.length}',
                Icons.bluetooth_searching,
                colorScheme.primary,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Central',
                '${store.connectedDevices.length}',
                Icons.bluetooth_connected,
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                context,
                'Peripheral',
                '${store.peripheralConnectedDevices.length}',
                Icons.bluetooth,
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Messages Sent',
                '${store.sentMessages.length}',
                Icons.send,
                Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Messages Received',
                '${store.receivedMessages.length}',
                Icons.inbox,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNetworkHealth(context),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
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
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
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

  Widget _buildNetworkHealth(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final healthScore = _calculateNetworkHealth();
    final healthColor = _getHealthColor(healthScore);
    final healthText = _getHealthText(healthScore);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: healthColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: healthColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_getHealthIcon(healthScore), color: healthColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Network Health',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  healthText,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: healthColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${(healthScore * 100).toInt()}%',
              style: textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateNetworkHealth() {
    if (!store.isBluetoothEnabled) return 0.0;

    double health = 0.0;

    // Base health if Bluetooth is enabled
    health += 0.2;

    // Connection health
    if (store.totalConnectedDevices > 0) {
      health += 0.3;
      if (store.totalConnectedDevices > 2) health += 0.1;
    }

    // Peripheral health
    if (store.isPeripheralActive) {
      health += 0.2;
    }

    // Message activity health
    if (store.sentMessages.isNotEmpty || store.receivedMessages.isNotEmpty) {
      health += 0.2;
    }

    return health.clamp(0.0, 1.0);
  }

  Color _getHealthColor(double health) {
    if (health >= 0.8) return Colors.green;
    if (health >= 0.6) return Colors.orange;
    if (health >= 0.4) return Colors.yellow;
    return Colors.red;
  }

  String _getHealthText(double health) {
    if (health >= 0.8) return 'Excellent mesh connectivity';
    if (health >= 0.6) return 'Good network performance';
    if (health >= 0.4) return 'Moderate connectivity';
    if (health >= 0.2) return 'Limited network access';
    return 'Network unavailable';
  }

  IconData _getHealthIcon(double health) {
    if (health >= 0.8) return Icons.signal_cellular_4_bar;
    if (health >= 0.6) return Icons.signal_cellular_alt;
    if (health >= 0.4) return Icons.signal_cellular_alt_2_bar;
    if (health >= 0.2) return Icons.signal_cellular_alt_1_bar;
    return Icons.signal_cellular_0_bar;
  }

  Color _getConnectionColor(int count) {
    if (count >= 3) return Colors.green;
    if (count >= 1) return Colors.orange;
    return Colors.grey;
  }
}
