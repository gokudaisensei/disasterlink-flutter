import 'package:flutter/material.dart';
import '../../domain/models/message_models.dart';
import '../../domain/constants/ble_constants.dart';
import '../../../../shared/widgets/common_widgets.dart';

class MessageHistorySection extends StatelessWidget {
  final List<DisasterLinkMessage> messages;
  final bool showSent;
  final bool showReceived;

  const MessageHistorySection({
    super.key,
    required this.messages,
    this.showSent = true,
    this.showReceived = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Filter messages based on type (sent/received would need to be determined differently)
    final filteredMessages = messages.where((message) {
      // For now, show all messages since we don't have a clear way to distinguish sent vs received
      return true;
    }).toList();

    // Sort by timestamp (newest first)
    filteredMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Message History',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (filteredMessages.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${filteredMessages.length}',
                  style: textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (filteredMessages.isEmpty)
          EmptyState(
            icon: Icons.message,
            title: 'No Messages',
            subtitle: 'Send your first emergency message to get started',
          )
        else
          ...filteredMessages
              .take(10)
              .map((message) => _buildMessageCard(context, message)),
        if (filteredMessages.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton(
                onPressed: () {
                  // TODO: Navigate to full message history
                },
                child: Text('View All ${filteredMessages.length} Messages'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageCard(BuildContext context, DisasterLinkMessage message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final messageTypeColor = _getMessageTypeColor(message.type);
    final priorityColor = _getPriorityColor(message.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: messageTypeColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: messageTypeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getMessageTypeIcon(message.type),
                  color: messageTypeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getMessageTypeLabel(message.type),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: messageTypeColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            message.priority.name.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: priorityColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${message.senderName} • ${_formatTimestamp(message.timestamp)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (message.requiresAck)
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.orange,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Message content
          _buildMessageContent(context, message),

          // Message metadata
          const SizedBox(height: 8),
          _buildMessageMetadata(context, message),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    BuildContext context,
    DisasterLinkMessage message,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    switch (message.type) {
      case MessageType.emergencySos:
        final lat = message.payload['latitude'] as double?;
        final lng = message.payload['longitude'] as double?;
        final info = message.payload['additionalInfo'] as String?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'EMERGENCY SOS',
                    style: textTheme.labelMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (lat != null && lng != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, color: colorScheme.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Location: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (info != null && info.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(info, style: textTheme.bodyMedium),
            ],
          ],
        );

      case MessageType.textMessage:
        final text = message.payload['text'] as String? ?? '';
        return Text(text, style: textTheme.bodyMedium);

      case MessageType.locationShare:
        final lat = message.payload['latitude'] as double?;
        final lng = message.payload['longitude'] as double?;
        final locationName = message.payload['locationName'] as String?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: colorScheme.primary, size: 16),
                const SizedBox(width: 4),
                Text(
                  locationName ?? 'Shared Location',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (lat != null && lng != null) ...[
              const SizedBox(height: 4),
              Text(
                '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        );

      case MessageType.resourceRequest:
        final resourceType = message.payload['resourceType'] as String? ?? '';
        final quantity = message.payload['quantity'] as int? ?? 0;
        final description = message.payload['description'] as String?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request: $quantity x $resourceType',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        );

      case MessageType.statusUpdate:
        final status = message.payload['status'] as String? ?? '';
        return Text('Status: $status', style: textTheme.bodyMedium);

      case MessageType.acknowledgment:
        final originalMessageId =
            message.payload['originalMessageId'] as String? ?? '';
        return Text(
          'Acknowledged message: ${originalMessageId.substring(0, 8)}...',
          style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
        );

      case MessageType.heartbeat:
        return Text(
          'Device heartbeat',
          style: textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        );
    }
  }

  Widget _buildMessageMetadata(
    BuildContext context,
    DisasterLinkMessage message,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 12,
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          'TTL: ${message.ttl}s',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.data_usage,
          size: 12,
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          '${message.sizeInBytes}B',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        if (message.hopCount > 0) ...[
          const SizedBox(width: 12),
          Icon(
            Icons.hub,
            size: 12,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(width: 4),
          Text(
            '${message.hopCount} hops',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ],
    );
  }

  Color _getMessageTypeColor(MessageType type) {
    switch (type) {
      case MessageType.emergencySos:
        return Colors.red;
      case MessageType.textMessage:
        return Colors.blue;
      case MessageType.locationShare:
        return Colors.green;
      case MessageType.resourceRequest:
        return Colors.orange;
      case MessageType.statusUpdate:
        return Colors.purple;
      case MessageType.acknowledgment:
        return Colors.grey;
      case MessageType.heartbeat:
        return Colors.teal;
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

  IconData _getMessageTypeIcon(MessageType type) {
    switch (type) {
      case MessageType.emergencySos:
        return Icons.warning;
      case MessageType.textMessage:
        return Icons.message;
      case MessageType.locationShare:
        return Icons.location_on;
      case MessageType.resourceRequest:
        return Icons.inventory;
      case MessageType.statusUpdate:
        return Icons.info;
      case MessageType.acknowledgment:
        return Icons.check;
      case MessageType.heartbeat:
        return Icons.favorite;
    }
  }

  String _getMessageTypeLabel(MessageType type) {
    switch (type) {
      case MessageType.emergencySos:
        return 'Emergency SOS';
      case MessageType.textMessage:
        return 'Text Message';
      case MessageType.locationShare:
        return 'Location Share';
      case MessageType.resourceRequest:
        return 'Resource Request';
      case MessageType.statusUpdate:
        return 'Status Update';
      case MessageType.acknowledgment:
        return 'Acknowledgment';
      case MessageType.heartbeat:
        return 'Heartbeat';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
