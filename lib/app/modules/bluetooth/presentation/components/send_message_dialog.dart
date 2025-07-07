import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../domain/constants/ble_constants.dart';

class SendMessageDialog extends StatefulWidget {
  final Function(
    String text,
    MessagePriority priority,
    BluetoothDevice? targetDevice,
  )
  onSendMessage;
  final List<BluetoothDevice> availableDevices;

  const SendMessageDialog({
    super.key,
    required this.onSendMessage,
    required this.availableDevices,
  });

  @override
  State<SendMessageDialog> createState() => _SendMessageDialogState();
}

class _SendMessageDialogState extends State<SendMessageDialog> {
  final TextEditingController _textController = TextEditingController();
  MessagePriority _selectedPriority = MessagePriority.normal;
  BluetoothDevice? _selectedDevice;
  bool _isBroadcast = true;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.send, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Send Message',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Message input
            Text(
              'Message',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Enter your emergency message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),

            // Priority selection
            Text(
              'Priority',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: MessagePriority.values.map((priority) {
                  return RadioListTile<MessagePriority>(
                    title: Row(
                      children: [
                        Icon(
                          _getPriorityIcon(priority),
                          color: _getPriorityColor(priority),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getPriorityLabel(priority),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      _getPriorityDescription(priority),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    value: priority,
                    groupValue: _selectedPriority,
                    onChanged: (MessagePriority? value) {
                      if (value != null) {
                        setState(() {
                          _selectedPriority = value;
                        });
                      }
                    },
                    activeColor: _getPriorityColor(priority),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Target selection
            Text(
              'Target',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: Row(
                      children: [
                        Icon(
                          Icons.broadcast_on_personal,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Broadcast to All',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      'Send to all connected devices',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    value: true,
                    groupValue: _isBroadcast,
                    onChanged: (bool? value) {
                      if (value != null) {
                        setState(() {
                          _isBroadcast = value;
                          if (_isBroadcast) _selectedDevice = null;
                        });
                      }
                    },
                    activeColor: colorScheme.primary,
                  ),
                  RadioListTile<bool>(
                    title: Row(
                      children: [
                        Icon(Icons.person, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Send to Specific Device',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      'Choose a specific connected device',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    value: false,
                    groupValue: _isBroadcast,
                    onChanged: (bool? value) {
                      if (value != null) {
                        setState(() {
                          _isBroadcast = !value;
                        });
                      }
                    },
                    activeColor: Colors.orange,
                  ),
                ],
              ),
            ),

            // Device selection (if not broadcast)
            if (!_isBroadcast) ...[
              const SizedBox(height: 16),
              Text(
                'Select Device',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.availableDevices.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No devices available. Connect to a device first.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: widget.availableDevices.map((device) {
                      final deviceName = device.platformName.isNotEmpty
                          ? device.platformName
                          : 'Unknown Device';
                      return RadioListTile<BluetoothDevice>(
                        title: Text(
                          deviceName,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          device.remoteId.toString(),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        value: device,
                        groupValue: _selectedDevice,
                        onChanged: (BluetoothDevice? value) {
                          setState(() {
                            _selectedDevice = value;
                          });
                        },
                        activeColor: colorScheme.primary,
                      );
                    }).toList(),
                  ),
                ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _canSendMessage() ? _sendMessage : null,
                  icon: Icon(Icons.send, size: 18),
                  label: Text('Send Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getPriorityColor(_selectedPriority),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canSendMessage() {
    final hasText = _textController.text.trim().isNotEmpty;
    final hasTarget = _isBroadcast || _selectedDevice != null;
    return hasText && hasTarget;
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(
        text,
        _selectedPriority,
        _isBroadcast ? null : _selectedDevice,
      );
      Navigator.of(context).pop();
    }
  }

  Color _getPriorityColor(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.critical:
        return Colors.red;
      case MessagePriority.high:
        return Colors.orange;
      case MessagePriority.normal:
        return Colors.blue;
      case MessagePriority.low:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.critical:
        return Icons.warning;
      case MessagePriority.high:
        return Icons.priority_high;
      case MessagePriority.normal:
        return Icons.message;
      case MessagePriority.low:
        return Icons.low_priority;
    }
  }

  String _getPriorityLabel(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.critical:
        return 'Critical';
      case MessagePriority.high:
        return 'High';
      case MessagePriority.normal:
        return 'Normal';
      case MessagePriority.low:
        return 'Low';
    }
  }

  String _getPriorityDescription(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.critical:
        return 'Life-threatening emergency';
      case MessagePriority.high:
        return 'Urgent assistance needed';
      case MessagePriority.normal:
        return 'Standard communication';
      case MessagePriority.low:
        return 'Non-urgent information';
    }
  }
}
