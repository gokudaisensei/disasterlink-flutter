import 'package:flutter/material.dart';
import '../stores/bluetooth_store.dart';
import '../../../../shared/widgets/common_widgets.dart';

class DeviceListSection extends StatelessWidget {
  final String title;
  final List<BluetoothDevice> devices;
  final String emptyMessage;
  final IconData emptyIcon;
  final Function(BluetoothDevice)? onDeviceAction;
  final String? actionLabel;
  final IconData? actionIcon;
  final Color? actionColor;
  final bool isLoading;

  const DeviceListSection({
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
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: device.isConnected
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
                  color: _getDeviceTypeColor(device.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getDeviceIcon(device.type),
                  color: _getDeviceTypeColor(device.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.signal_cellular_alt,
                          size: 16,
                          color: _getSignalColor(device.signalStrength),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${device.signalStrength}%',
                          style: textTheme.bodySmall?.copyWith(
                            color: _getSignalColor(device.signalStrength),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: device.isConnected
                                ? Colors.green.withOpacity(0.1)
                                : colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            device.isConnected ? 'Connected' : 'Available',
                            style: textTheme.labelSmall?.copyWith(
                              color: device.isConnected
                                  ? Colors.green
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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
                    icon: Icon(
                      actionIcon ?? Icons.link,
                      size: 16,
                    ),
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
          _buildSignalStrengthIndicator(context, device.signalStrength),
        ],
      ),
    );
  }

  Widget _buildSignalStrengthIndicator(BuildContext context, int strength) {
    final colorScheme = Theme.of(context).colorScheme;
    final signalColor = _getSignalColor(strength);

    return Row(
      children: [
        Icon(
          Icons.signal_cellular_alt,
          size: 16,
          color: signalColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: strength / 100,
            backgroundColor: colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(signalColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _getSignalStrengthText(strength),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: signalColor,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  IconData _getDeviceIcon(BluetoothDeviceType type) {
    switch (type) {
      case BluetoothDeviceType.phone:
        return Icons.smartphone;
      case BluetoothDeviceType.tablet:
        return Icons.tablet;
      case BluetoothDeviceType.laptop:
        return Icons.laptop;
      case BluetoothDeviceType.speaker:
        return Icons.speaker;
      case BluetoothDeviceType.headphones:
        return Icons.headphones;
      case BluetoothDeviceType.watch:
        return Icons.watch;
      case BluetoothDeviceType.unknown:
        return Icons.device_unknown;
    }
  }

  Color _getDeviceTypeColor(BluetoothDeviceType type) {
    switch (type) {
      case BluetoothDeviceType.phone:
        return Colors.blue;
      case BluetoothDeviceType.tablet:
        return Colors.purple;
      case BluetoothDeviceType.laptop:
        return Colors.green;
      case BluetoothDeviceType.speaker:
        return Colors.orange;
      case BluetoothDeviceType.headphones:
        return Colors.red;
      case BluetoothDeviceType.watch:
        return Colors.teal;
      case BluetoothDeviceType.unknown:
        return Colors.grey;
    }
  }

  Color _getSignalColor(int strength) {
    if (strength >= 80) return Colors.green;
    if (strength >= 60) return Colors.orange;
    if (strength >= 30) return Colors.red;
    return Colors.grey;
  }

  String _getSignalStrengthText(int strength) {
    if (strength >= 80) return 'Excellent';
    if (strength >= 60) return 'Good';
    if (strength >= 30) return 'Poor';
    return 'Very Poor';
  }
}
