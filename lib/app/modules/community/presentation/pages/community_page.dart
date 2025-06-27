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
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community Network',
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
            // Community Network Stats
            _buildNetworkStats(context),
            
            const SizedBox(height: 20),
            
            // Social Communication Features
            _buildSocialActions(context),
            
            const SizedBox(height: 20),
            
            // Emergency Team Coordination
            _buildEmergencyTeamSection(context),
            
            const SizedBox(height: 20),
            
            // Community Posts/Feed
            _buildCommunityFeed(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewPostDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'New Community Post',
      ),
    );
  }

  Widget _buildNetworkStats(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network Overview',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNetworkStat(
                'Connected Users',
                '${_communityStore.connectedUsers.length}',
                Icons.people,
                theme.colorScheme.onPrimaryContainer,
              ),
              _buildNetworkStat(
                'Nearby Users',
                '${_communityStore.nearbyUsers.length}',
                Icons.radar,
                theme.colorScheme.onPrimaryContainer,
              ),
              _buildNetworkStat(
                'Messages',
                '${_messagingStore.allMessages.length}',
                Icons.message,
                theme.colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSocialActions(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Social Communication',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSocialActionCard(
                'Find People',
                Icons.people_alt,
                Colors.blue,
                () => Modular.to.pushNamed('/community/discovery'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSocialActionCard(
                'Group Chat',
                Icons.forum,
                Colors.green,
                () => _createGroupChat(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSocialActionCard(
                'Share Resources',
                Icons.inventory,
                Colors.orange,
                () => _shareResources(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSocialActionCard(
                'Community Board',
                Icons.announcement,
                Colors.purple,
                () => _showCommunityBoard(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTeamSection(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final emergencyUsers = _communityStore.connectedUsers
        .where((user) => user.status == UserStatus.emergency || user.status == UserStatus.needHelp)
        .toList();
    final helpers = _communityStore.connectedUsers
        .where((user) => user.status == UserStatus.canHelp)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Team Coordination',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        if (emergencyUsers.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emergency, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Users Needing Help (${emergencyUsers.length})',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...emergencyUsers.take(3).map((user) => _buildUserTile(user, Colors.red)),
                if (emergencyUsers.length > 3)
                  TextButton(
                    onPressed: () => _showAllEmergencyUsers(context),
                    child: Text('View all ${emergencyUsers.length} users'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        if (helpers.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.volunteer_activism, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Available Helpers (${helpers.length})',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...helpers.take(3).map((user) => _buildUserTile(user, Colors.green)),
                if (helpers.length > 3)
                  TextButton(
                    onPressed: () => _showAllHelpers(context),
                    child: Text('View all ${helpers.length} helpers'),
                  ),
              ],
            ),
          ),
        ],
        
        if (emergencyUsers.isEmpty && helpers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
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
                  'No emergency coordination needed',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUserTile(UserProfile user, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: accentColor.withOpacity(0.2),
            child: Text(
              user.name.substring(0, 1),
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  user.location ?? 'Location unknown',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Modular.to.pushNamed('/community/messaging', arguments: user.id),
            icon: const Icon(Icons.message, size: 20),
            tooltip: 'Message',
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityFeed(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final recentMessages = _messagingStore.allMessages
        .where((m) => m.type.toString() != 'MessageType.emergency')
        .take(5)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Community Posts',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showNewPostDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('New Post'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (recentMessages.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                  'No community posts yet',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Be the first to share something!',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        else
          ...recentMessages.map((message) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        message.senderName.substring(0, 1),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.senderName,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatTime(message.timestamp),
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _likePost(message.id),
                      icon: const Icon(Icons.favorite_border, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message.content,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _replyToPost(message),
                      icon: const Icon(Icons.comment, size: 16),
                      label: const Text('Reply'),
                    ),
                    TextButton.icon(
                      onPressed: () => _sharePost(message),
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share'),
                    ),
                  ],
                ),
              ],
            ),
          )),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _createGroupChat(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Group chat feature coming soon'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareResources(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Resources'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What resources can you share?'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                'Food',
                'Water',
                'Shelter',
                'Medical Supplies',
                'Transportation',
                'Tools',
                'Communication',
                'Other',
              ].map((resource) => ActionChip(
                label: Text(resource),
                onPressed: () {
                  Navigator.pop(context);
                  _postResourceShare(resource);
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

  void _showCommunityBoard(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Community board feature coming soon'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _showAllEmergencyUsers(BuildContext context) {
    // Implementation for showing all emergency users
  }

  void _showAllHelpers(BuildContext context) {
    // Implementation for showing all helpers
  }

  void _showNewPostDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Community Post'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Share an update with the community...',
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
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _postResourceShare(String resource) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared: $resource available'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _postCommunityUpdate(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Community post shared'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _likePost(String postId) {
    // Implementation for liking a post
  }

  void _replyToPost(dynamic message) {
    // Implementation for replying to a post
  }

  void _sharePost(dynamic message) {
    // Implementation for sharing a post
  }
}
