import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../../shared/widgets/common_widgets.dart';

class RealDeviceListSection extends StatelessWidget {
  final String title;
  final List<BluetoothDevice> devices;
  final String emptyMessage;
  final IconData emptyIcon;
  final Function(BluetoothDevice)? onDeviceAction;
  final String? actionLabel;
  final IconData? actionIcon;
  final Color? actionColor;
  final bool isLoading;

  const RealDeviceListSection({
    super.key,
    required this.title,
    required this.devices,
    required this.emptyMessage,
    required this.emptyIcon,
    this.onDeviceAction,
    this.actionLabel,
    this.actionIcon,
    this.actionColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (devices.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${devices.length}',
                  style: textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (devices.isEmpty)
          EmptyState(
            icon: emptyIcon,
            title: 'No Devices',
            subtitle: emptyMessage,
          )
        else
          ...devices.map((device) => _buildDeviceCard(context, device)),
      ],
    );
  }

  Widget _buildDeviceCard(BuildContext context, BluetoothDevice device) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Get device connection state
    final isConnected = device.isConnected;
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : 'Unknown Device';
    final deviceId = device.remoteId.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? Colors.green.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getDeviceTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getDeviceIcon(),
                  color: _getDeviceTypeColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceName,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deviceId,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.bluetooth,
                          size: 16,
                          color: isConnected
                              ? Colors.green
                              : colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isConnected
                                ? Colors.green.withOpacity(0.1)
                                : colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isConnected ? 'Connected' : 'Available',
                            style: textTheme.labelSmall?.copyWith(
                              color: isConnected
                                  ? Colors.green
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (isConnected)
                          Icon(Icons.circle, size: 8, color: Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDeviceAction != null && actionLabel != null) ...[
                const SizedBox(width: 12),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => onDeviceAction!(device),
                    icon: Icon(actionIcon ?? Icons.link, size: 16),
                    label: Text(actionLabel!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor ?? colorScheme.primary,
                      foregroundColor: actionColor != null
                          ? Colors.white
                          : colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      textStyle: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _buildDeviceInfo(context, device),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo(BuildContext context, BluetoothDevice device) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildInfoItem(
            context,
            'Device ID',
            device.remoteId.toString().substring(0, 8) + '...',
            Icons.fingerprint,
          ),
          const SizedBox(width: 16),
          _buildInfoItem(context, 'Type', 'Emergency', Icons.emergency),
          const SizedBox(width: 16),
          _buildInfoItem(context, 'Protocol', 'BLE 5.0', Icons.bluetooth),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon() {
    // For now, return a generic emergency icon
    // In a real implementation, you could determine device type from advertisement data
    return Icons.emergency;
  }

  Color _getDeviceTypeColor() {
    // Return emergency red color for DisasterLink devices
    return Colors.red;
  }
}

/// Widget for peripheral connected devices
class PeripheralDeviceListSection extends StatelessWidget {
  final List<Map<String, dynamic>> devices;

  const PeripheralDeviceListSection({super.key, required this.devices});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Peripheral Connections',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (devices.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${devices.length}',
                  style: textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (devices.isEmpty)
          EmptyState(
            icon: Icons.bluetooth_disabled,
            title: 'No Peripheral Connections',
            subtitle: 'Enable peripheral mode to accept connections',
          )
        else
          ...devices.map(
            (device) => _buildPeripheralDeviceCard(context, device),
          ),
      ],
    );
  }

  Widget _buildPeripheralDeviceCard(
    BuildContext context,
    Map<String, dynamic> device,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final deviceId = device['deviceId'] as String;
    final deviceName = device['deviceName'] as String;
    final connectedAt = device['connectedAt'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.phone_android, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deviceId,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connected: ${DateTime.parse(connectedAt).toLocal().toString().split('.')[0]}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Connected',
              style: textTheme.labelSmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
