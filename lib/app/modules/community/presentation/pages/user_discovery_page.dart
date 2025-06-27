import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../stores/community_store.dart';
import '../components/nearby_users_list.dart';

class UserDiscoveryPage extends StatefulWidget {
  const UserDiscoveryPage({super.key});

  @override
  State<UserDiscoveryPage> createState() => _UserDiscoveryPageState();
}

class _UserDiscoveryPageState extends State<UserDiscoveryPage> {
  final CommunityStore _store = Modular.get<CommunityStore>();

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    _store.startUserDiscovery();
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
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discover Users',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _store.isDiscovering ? Icons.stop : Icons.search,
              color: _store.isDiscovering ? Colors.orange : colorScheme.primary,
            ),
            onPressed: () {
              if (_store.isDiscovering) {
                _store.stopUserDiscovery();
              } else {
                _store.startUserDiscovery();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Discovery Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? colorScheme.surfaceVariant : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    _store.isDiscovering ? Icons.radar : Icons.search_off,
                    size: 48,
                    color: _store.isDiscovering ? Colors.green : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _store.isDiscovering ? 'Discovering nearby users...' : 'Discovery stopped',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_store.nearbyUsers.length} users found',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Users',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _store.refreshNearbyUsers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Users List
            Expanded(
              child: _store.nearbyUsers.isEmpty && !_store.isDiscovering
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No users discovered yet',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the search button to start discovering',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : NearbyUsersList(
                    title: 'Discovered Users',
                    users: _store.nearbyUsers,
                    emptyMessage: 'No users found',
                    onUserAction: (user) {
                      _showUserActions(context, user);
                    },
                    actionLabel: 'Connect',
                    actionIcon: Icons.connect_without_contact,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserActions(BuildContext context, dynamic user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to messaging
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.connect_without_contact),
              title: const Text('Connect'),
              onTap: () {
                Navigator.pop(context);
                _store.connectToUser(user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('Report Emergency'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Report emergency
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _store.stopUserDiscovery();
    super.dispose();
  }
}
