import 'package:flutter/material.dart';
import '../stores/community_store.dart';
import '../stores/messaging_store.dart';

class NetworkStatsCard extends StatelessWidget {
  final CommunityStore communityStore;
  final MessagingStore messagingStore;

  const NetworkStatsCard({
    super.key,
    required this.communityStore,
    required this.messagingStore,
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
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Network Statistics',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: messagingStore.isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                messagingStore.isConnected ? 'Online' : 'Offline',
                style: textTheme.labelSmall?.copyWith(
                  color: messagingStore.isConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                context,
                'Connected',
                '${communityStore.connectedUsers.length}',
                Icons.link,
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Nearby',
                '${communityStore.nearbyUsers.length}',
                Icons.people_outline,
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Messages',
                '${messagingStore.allMessages.length}',
                Icons.message,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                context,
                'Trust Score',
                '${communityStore.averageTrustScore.toStringAsFixed(1)}',
                Icons.verified_user,
                Colors.purple,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Channels',
                '${messagingStore.channels.length}',
                Icons.forum,
                Colors.teal,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Emergency',
                '${_getEmergencyCount()}',
                Icons.emergency,
                Colors.red,
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

  int _getEmergencyCount() {
    return messagingStore.allMessages
        .where((m) => m.type == MessageType.emergency || m.priority == MessagePriority.critical)
        .length;
  }
}
