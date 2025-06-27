import 'package:flutter/material.dart';
import '../stores/community_store.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../shared/widgets/common_widgets.dart';

class NearbyUsersList extends StatelessWidget {
  final String title;
  final List<UserProfile> users;
  final String emptyMessage;
  final Function(UserProfile)? onUserAction;
  final String? actionLabel;
  final IconData? actionIcon;
  final Color? actionColor;
  final bool isLoading;

  const NearbyUsersList({
    super.key,
    required this.title,
    required this.users,
    required this.emptyMessage,
    this.onUserAction,
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
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (users.isNotEmpty)
              Text(
                '${users.length} ${users.length == 1 ? 'user' : 'users'}',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (users.isEmpty)
          EmptyState(
            icon: isLoading ? Icons.people_outline : Icons.people_outline,
            title: 'No Users',
            subtitle: emptyMessage,
          )
        else
          ...users.map((user) => _buildUserCard(context, user)),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context, UserProfile user) {
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
          color: _getUserStatusColor(user.status).withOpacity(0.3),
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
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                    child: Icon(
                      _getRoleIcon(user.role),
                      color: _getRoleColor(user.role),
                      size: 24,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getUserStatusColor(user.status),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.role).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.roleDisplayName,
                            style: textTheme.labelSmall?.copyWith(
                              color: _getRoleColor(user.role),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.signal_cellular_alt,
                          size: 16,
                          color: _getSignalColor(user.signalStrength),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user.signalStrength}%',
                          style: textTheme.bodySmall?.copyWith(
                            color: _getSignalColor(user.signalStrength),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.trustScore.toStringAsFixed(1),
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
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
                            color: _getUserStatusColor(user.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.statusDisplayName,
                            style: textTheme.labelSmall?.copyWith(
                              color: _getUserStatusColor(user.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (user.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.location!,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (user.skills.isNotEmpty || user.resources.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (user.skills.isNotEmpty) ...[
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: user.skills.take(3).map((skill) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    skill,
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.blue,
                      fontSize: 10,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 4),
            ],
            if (user.resources.isNotEmpty) ...[
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: user.resources.take(2).map((resource) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    resource,
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.green,
                      fontSize: 10,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
          if (onUserAction != null && actionLabel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : () => onUserAction!(user),
                    icon: isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                            ),
                          )
                        : Icon(actionIcon ?? Icons.link, size: 16),
                    label: Text(actionLabel!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor ?? colorScheme.primary,
                      foregroundColor: actionColor != null
                          ? Colors.white
                          : colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showUserDetails(context, user),
                  icon: const Icon(Icons.info_outline),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Role', user.roleDisplayName),
            _buildDetailRow('Status', user.statusDisplayName),
            _buildDetailRow('Trust Score', '${user.trustScore}/5.0'),
            _buildDetailRow('Signal', '${user.signalStrength}%'),
            if (user.location != null) _buildDetailRow('Location', user.location!),
            if (user.skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Skills:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...user.skills.map((skill) => Text('• $skill')),
            ],
            if (user.resources.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Resources:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...user.resources.map((resource) => Text('• $resource')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to direct messaging
            },
            child: const Text('Message'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.civilian:
        return Icons.person;
      case UserRole.volunteer:
        return Icons.volunteer_activism;
      case UserRole.firstResponder:
        return Icons.local_fire_department;
      case UserRole.medicalPersonnel:
        return Icons.medical_services;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.civilian:
        return Colors.grey;
      case UserRole.volunteer:
        return Colors.blue;
      case UserRole.firstResponder:
        return Colors.red;
      case UserRole.medicalPersonnel:
        return Colors.green;
      case UserRole.admin:
        return Colors.purple;
    }
  }

  Color _getUserStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.safe:
        return Colors.green;
      case UserStatus.needHelp:
        return Colors.orange;
      case UserStatus.canHelp:
        return Colors.blue;
      case UserStatus.offline:
        return Colors.grey;
      case UserStatus.emergency:
        return Colors.red;
    }
  }

  Color _getSignalColor(int strength) {
    if (strength >= 80) return Colors.green;
    if (strength >= 60) return Colors.orange;
    if (strength >= 30) return Colors.red;
    return Colors.grey;
  }
}
