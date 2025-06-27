import 'package:flutter/material.dart';
import '../stores/community_store.dart';
import '../stores/messaging_store.dart';
import '../../domain/entities/user_profile.dart';

class EmergencyFeed extends StatelessWidget {
  final CommunityStore communityStore;
  final MessagingStore messagingStore;

  const EmergencyFeed({
    super.key,
    required this.communityStore,
    required this.messagingStore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final emergencyUsers = communityStore.getUsersByStatus(UserStatus.emergency);
    final emergencyMessages = messagingStore.getEmergencyMessages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Dashboard',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        
        // Emergency Statistics
        _buildEmergencyStats(context),
        const SizedBox(height: 20),
        
        // Emergency Users
        if (emergencyUsers.isNotEmpty) ...[
          Text(
            'Users in Emergency',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          ...emergencyUsers.map((user) => _buildEmergencyUserCard(context, user)),
          const SizedBox(height: 20),
        ],
        
        // Emergency Messages
        Text(
          'Emergency Communications',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        if (emergencyMessages.isEmpty)
          _buildEmptyEmergencyState(context)
        else
          ...emergencyMessages.map((message) => _buildEmergencyMessageCard(context, message)),
      ],
    );
  }

  Widget _buildEmergencyStats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final emergencyCount = communityStore.getUsersByStatus(UserStatus.emergency).length;
    final needHelpCount = communityStore.getUsersByStatus(UserStatus.needHelp).length;
    final canHelpCount = communityStore.getUsersByStatus(UserStatus.canHelp).length;
    final emergencyMessageCount = messagingStore.getEmergencyMessages().length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              Text(
                'Emergency Status Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                context,
                'Emergency',
                '$emergencyCount',
                Icons.crisis_alert,
                Colors.red,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Need Help',
                '$needHelpCount',
                Icons.help_outline,
                Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Can Help',
                '$canHelpCount',
                Icons.volunteer_activism,
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Alerts',
                '$emergencyMessageCount',
                Icons.notification_important,
                Colors.purple,
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
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyUserCard(BuildContext context, UserProfile user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.red.withOpacity(0.1),
                child: Icon(Icons.person, color: Colors.red),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (user.location != null)
                  Text(
                    user.location!,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                Text(
                  'Last seen: ${_formatLastSeen(user.lastSeen)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              ElevatedButton(
                onPressed: () => _respondToEmergency(context, user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Respond', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => _contactUser(context, user),
                child: const Text('Contact', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyMessageCard(BuildContext context, ChatMessage message) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isEmergency = message.type == MessageType.emergency || 
                       message.priority == MessagePriority.critical;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEmergency ? Colors.red.withOpacity(0.05) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEmergency ? Colors.red.withOpacity(0.3) : 
                 theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getMessageIcon(message.type),
                color: _getMessageColor(message.priority),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.senderName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getMessageColor(message.priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPriorityText(message.priority),
                  style: textTheme.labelSmall?.copyWith(
                    color: _getMessageColor(message.priority),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.content,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatMessageTime(message.timestamp),
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              if (isEmergency) ...[
                TextButton.icon(
                  onPressed: () => _respondToMessage(context, message),
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Respond'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEmergencyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Emergencies',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.green[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All users are safe. Emergency communications will appear here.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getMessageIcon(MessageType type) {
    switch (type) {
      case MessageType.emergency:
        return Icons.emergency;
      case MessageType.resource:
        return Icons.inventory;
      case MessageType.location:
        return Icons.location_on;
      case MessageType.system:
        return Icons.info;
      default:
        return Icons.message;
    }
  }

  Color _getMessageColor(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.critical:
        return Colors.red;
      case MessagePriority.high:
        return Colors.orange;
      case MessagePriority.normal:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.critical:
        return 'CRITICAL';
      case MessagePriority.high:
        return 'HIGH';
      case MessagePriority.normal:
        return 'NORMAL';
      default:
        return 'LOW';
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _respondToEmergency(BuildContext context, UserProfile user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Responding to ${user.name}\'s emergency'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _contactUser(BuildContext context, UserProfile user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contacting ${user.name}')),
    );
  }

  void _respondToMessage(BuildContext context, ChatMessage message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Responding to ${message.senderName}')),
    );
  }
}
