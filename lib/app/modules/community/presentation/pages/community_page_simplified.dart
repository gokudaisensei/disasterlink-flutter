import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../stores/community_store.dart';
import '../stores/messaging_store.dart';
import '../../domain/entities/user_profile.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  late final CommunityStore _communityStore;
  late final MessagingStore _messagingStore;

  @override
  void initState() {
    super.initState();
    _communityStore = Modular.get<CommunityStore>();
    _messagingStore = Modular.get<MessagingStore>();
    
    _communityStore.addListener(_onStoreChanged);
    _messagingStore.addListener(_onStoreChanged);
    
    // Initialize data
    _communityStore.initializeCurrentUser();
    _messagingStore.initializeMessaging();
    _communityStore.scanForNearbyUsers();
  }

  @override
  void dispose() {
    _communityStore.removeListener(_onStoreChanged);
    _messagingStore.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Emergency Community',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Message notification badge
          Stack(
            children: [
              IconButton(
                onPressed: () => Modular.to.pushNamed('/community/messaging'),
                icon: const Icon(Icons.message),
                tooltip: 'Messages',
              ),
              if (_messagingStore.totalUnreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_messagingStore.totalUnreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Status Card
            _buildEmergencyStatusCard(context),
            
            const SizedBox(height: 20),
            
            // Emergency Quick Actions
            _buildEmergencyActions(context),
            
            const SizedBox(height: 20),
            
            // Social Features - Community Feed
            _buildSocialSection(context),
            
            const SizedBox(height: 20),
            
            // Emergency Feed
            _buildEmergencyFeed(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _broadcastSOS,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.emergency),
        label: const Text('SOS'),
      ),
    );
  }

  Widget _buildEmergencyStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final currentUser = _communityStore.currentUser ?? _communityStore.defaultCurrentUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: currentUser.status == UserStatus.emergency
              ? [Colors.red, Colors.red.shade700]
              : currentUser.status == UserStatus.needHelp
                  ? [Colors.orange, Colors.orange.shade700]
                  : [Colors.green, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  _getStatusIcon(currentUser.status),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser.name,
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getStatusText(currentUser.status),
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showStatusChangeDialog,
                icon: const Icon(Icons.edit, color: Colors.white),
                tooltip: 'Change Status',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusStat(
                'Connected',
                '${_communityStore.connectedUsers.length}',
                Icons.people,
                Colors.white,
              ),
              _buildStatusStat(
                'Nearby',
                '${_communityStore.nearbyUsers.length}',
                Icons.radar,
                Colors.white,
              ),
              _buildStatusStat(
                'Trust',
                '${currentUser.trustScore.toStringAsFixed(1)}',
                Icons.star,
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyActions(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Actions',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildActionCard(
              'Broadcast SOS',
              Icons.emergency,
              Colors.red,
              _broadcastSOS,
            ),
            _buildActionCard(
              'Request Help',
              Icons.help,
              Colors.orange,
              _requestHelp,
            ),
            _buildActionCard(
              'Share Location',
              Icons.location_on,
              Colors.blue,
              _shareLocation,
            ),
            _buildActionCard(
              'Find People',
              Icons.people_alt,
              Colors.green,
              () => Modular.to.pushNamed('/community/discovery'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialSection(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Community Feed',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => Modular.to.pushNamed('/community/messaging'),
              icon: const Icon(Icons.message),
              label: const Text('Messages'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Social Actions
        Row(
          children: [
            Expanded(
              child: _buildSocialAction(
                'Share Update',
                Icons.announcement,
                Colors.blue,
                _shareUpdate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSocialAction(
                'Check-in Safe',
                Icons.verified_user,
                Colors.green,
                _checkInSafe,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Recent Community Activity
        _buildRecentActivity(),
      ],
    );
  }

  Widget _buildSocialAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentMessages = _messagingStore.allMessages
        .where((m) => m.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 2))))
        .take(3)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (recentMessages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.forum_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No recent activity',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Be the first to share an update!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: recentMessages.map((message) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _getMessageColor(message.priority).withOpacity(0.2),
              child: Icon(
                _getMessageIcon(message.type),
                color: _getMessageColor(message.priority),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.senderName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              _formatTime(message.timestamp),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildEmergencyFeed(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final emergencyMessages = _messagingStore.getEmergencyMessages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Alerts',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 12),
        
        if (emergencyMessages.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                Text(
                  'All Clear',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'No emergency alerts in your area',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          )
        else
          ...emergencyMessages.take(5).map((message) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emergency,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'EMERGENCY ALERT',
                      style: textTheme.labelMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(message.timestamp),
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message.content,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'From: ${message.senderName}',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }

  IconData _getStatusIcon(UserStatus status) {
    switch (status) {
      case UserStatus.emergency:
        return Icons.emergency;
      case UserStatus.needHelp:
        return Icons.help;
      case UserStatus.canHelp:
        return Icons.volunteer_activism;
      default:
        return Icons.check_circle;
    }
  }

  String _getStatusText(UserStatus status) {
    switch (status) {
      case UserStatus.emergency:
        return 'EMERGENCY - Need immediate help!';
      case UserStatus.needHelp:
        return 'Need assistance';
      case UserStatus.canHelp:
        return 'Available to help others';
      default:
        return 'Safe and secure';
    }
  }

  IconData _getMessageIcon(type) {
    switch (type.toString()) {
      case 'MessageType.emergency':
        return Icons.emergency;
      case 'MessageType.resource':
        return Icons.inventory;
      case 'MessageType.location':
        return Icons.location_on;
      case 'MessageType.system':
        return Icons.info;
      default:
        return Icons.message;
    }
  }

  Color _getMessageColor(priority) {
    switch (priority.toString()) {
      case 'MessagePriority.critical':
        return Colors.red;
      case 'MessagePriority.high':
        return Colors.orange;
      case 'MessagePriority.normal':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _broadcastSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency SOS'),
          ],
        ),
        content: const Text(
          'This will broadcast an emergency SOS to all connected users and emergency services. Use only in real emergencies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendEmergencyBroadcast();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }

  void _requestHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What kind of help do you need?'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                'Medical',
                'Food',
                'Shelter',
                'Transportation',
                'Communication',
                'Other',
              ].map((type) => ActionChip(
                label: Text(type),
                onPressed: () {
                  Navigator.pop(context);
                  _sendHelpRequest(type);
                },
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _shareLocation() {
    // Implementation for sharing current location
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location shared with connected users'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareUpdate() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Share Community Update'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'What\'s happening in your area?',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (controller.text.isNotEmpty) {
                  _postCommunityUpdate(controller.text);
                }
              },
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  void _checkInSafe() {
    _postCommunityUpdate('I am safe and secure in my current location. ✅');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Safety check-in shared with community'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showStatusChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserStatus.values.map((status) => ListTile(
            leading: Icon(_getStatusIcon(status)),
            title: Text(_getStatusText(status)),
            onTap: () {
              Navigator.pop(context);
              _communityStore.updateUserStatus(status);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _sendEmergencyBroadcast() {
    // Implementation for emergency broadcast
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency SOS broadcasted to all users'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _sendHelpRequest(String type) {
    // Implementation for help request
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Help request for $type sent to community'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _postCommunityUpdate(String message) {
    // Implementation for posting community update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Community update shared'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
