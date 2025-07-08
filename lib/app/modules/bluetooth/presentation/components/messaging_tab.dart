import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../stores/real_bluetooth_store.dart';
import '../../domain/constants/ble_constants.dart';

class MessagingTab extends StatefulWidget {
  final BluetoothStore bluetoothStore;

  const MessagingTab({super.key, required this.bluetoothStore});

  @override
  State<MessagingTab> createState() => _MessagingTabState();
}

class _MessagingTabState extends State<MessagingTab> {
  final TextEditingController _messageController = TextEditingController();
  MessagePriority _selectedPriority = MessagePriority.normal;
  BluetoothDevice? _selectedDevice;
  bool _isBroadcast = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendEmergencySOS,
                    icon: const Icon(Icons.warning, color: Colors.white),
                    label: const Text('Emergency SOS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareLocation,
                    icon: const Icon(Icons.location_on, color: Colors.white),
                    label: const Text('Share Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Message Composition Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compose Message',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Message Input
                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        hintText: 'Enter your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a message';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Priority Selection
                    Text(
                      'Priority',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: MessagePriority.values.map((priority) {
                        final isSelected = _selectedPriority == priority;
                        return FilterChip(
                          selected: isSelected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getPriorityIcon(priority),
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : _getPriorityColor(priority),
                              ),
                              const SizedBox(width: 4),
                              Text(_getPriorityLabel(priority)),
                            ],
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedPriority = priority;
                              });
                            }
                          },
                          selectedColor: _getPriorityColor(priority),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Target Selection
                    Text(
                      'Send To',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Broadcast/Specific Device Toggle
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.3),
                        ),
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
                                const Text('Broadcast to All'),
                              ],
                            ),
                            subtitle: const Text(
                              'Send to all connected devices',
                            ),
                            value: true,
                            groupValue: _isBroadcast,
                            onChanged: (value) {
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
                                Icon(
                                  Icons.person,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Send to Specific Device',
                                  style: TextStyle(
                                    color:
                                        widget
                                            .bluetoothStore
                                            .connectedDevices
                                            .isEmpty
                                        ? colorScheme.onSurface.withOpacity(0.4)
                                        : null,
                                  ),
                                ),
                                if (widget
                                    .bluetoothStore
                                    .connectedDevices
                                    .isEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'No devices',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.5),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              widget.bluetoothStore.connectedDevices.isEmpty
                                  ? 'No connected devices available'
                                  : 'Choose a specific connected device',
                            ),
                            value: false,
                            groupValue: _isBroadcast,
                            onChanged:
                                widget.bluetoothStore.connectedDevices.isEmpty
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() {
                                        _isBroadcast = value;
                                      });
                                    }
                                  },
                            activeColor: Colors.orange,
                          ),
                        ],
                      ),
                    ),

                    // Device Selection (if specific device is selected)
                    if (!_isBroadcast) ...[
                      const SizedBox(height: 16),
                      if (widget.bluetoothStore.connectedDevices.isEmpty)
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
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
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
                            children: widget.bluetoothStore.connectedDevices
                                .map((device) {
                                  final deviceName =
                                      device.platformName.isNotEmpty
                                      ? device.platformName
                                      : 'Unknown Device';
                                  return RadioListTile<BluetoothDevice>(
                                    title: Text(deviceName),
                                    subtitle: Text(device.remoteId.toString()),
                                    value: device,
                                    groupValue: _selectedDevice,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedDevice = value;
                                      });
                                    },
                                    activeColor: colorScheme.primary,
                                  );
                                })
                                .toList(),
                          ),
                        ),
                    ],

                    const SizedBox(height: 24),

                    // Send Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _canSendMessage() ? _sendMessage : null,
                        icon: const Icon(Icons.send),
                        label: const Text('Send Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getPriorityColor(_selectedPriority),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Connection Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.bluetooth,
                          color: widget.bluetoothStore.isBluetoothEnabled
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bluetooth: ${widget.bluetoothStore.isBluetoothEnabled ? "Enabled" : "Disabled"}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.devices,
                          color: widget.bluetoothStore.totalConnectedDevices > 0
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Connected Devices: ${widget.bluetoothStore.totalConnectedDevices}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSendMessage() {
    final hasText = _messageController.text.trim().isNotEmpty;
    final hasTarget = _isBroadcast || _selectedDevice != null;
    return hasText && hasTarget && widget.bluetoothStore.isBluetoothEnabled;
  }

  void _sendMessage() async {
    if (_formKey.currentState?.validate() ?? false) {
      final text = _messageController.text.trim();
      try {
        await widget.bluetoothStore.sendTextMessage(
          text: text,
          targetDevice: _isBroadcast ? null : _selectedDevice,
          priority: _selectedPriority,
        );

        _messageController.clear();
        setState(() {
          _selectedPriority = MessagePriority.normal;
          _isBroadcast = true;
          _selectedDevice = null;
        });

        _showSnackBar('Message sent successfully', Colors.green);
      } catch (e) {
        _showSnackBar('Failed to send message: $e', Colors.red);
      }
    }
  }

  void _sendEmergencySOS() async {
    try {
      await widget.bluetoothStore.sendEmergencySOS(
        additionalInfo: 'Emergency SOS sent from DisasterLink app',
      );
      _showSnackBar('Emergency SOS sent to all devices', Colors.red);
    } catch (e) {
      _showSnackBar('Failed to send SOS: $e', Colors.red);
    }
  }

  void _shareLocation() async {
    try {
      await widget.bluetoothStore.sendLocationShare(
        locationName: 'Current Location',
      );
      _showSnackBar('Location shared with network', Colors.blue);
    } catch (e) {
      _showSnackBar('Failed to share location: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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
}
