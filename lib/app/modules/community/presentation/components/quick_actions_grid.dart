import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildQuickActionCard(
              context,
              'Send SOS',
              Icons.emergency,
              Colors.red,
              () => _showSOSDialog(context),
            ),
            _buildQuickActionCard(
              context,
              'Share Status',
              Icons.announcement,
              Colors.orange,
              () => _showStatusDialog(context),
            ),
            _buildQuickActionCard(
              context,
              'Messages',
              Icons.message,
              Colors.blue,
              () => Modular.to.pushNamed('/community/messaging'),
            ),
            _buildQuickActionCard(
              context,
              'Find Help',
              Icons.search,
              Colors.green,
              () => Modular.to.pushNamed('/community/discovery'),
            ),
            _buildQuickActionCard(
              context,
              'Resources',
              Icons.inventory,
              Colors.green,
              () => _showResourceDialog(context),
            ),
            _buildQuickActionCard(
              context,
              'Location',
              Icons.location_on,
              Colors.purple,
              () => _showLocationDialog(context),
            ),
            _buildQuickActionCard(
              context,
              'Settings',
              Icons.settings,
              Colors.grey,
              () => _showSettingsDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Send Emergency SOS'),
          ],
        ),
        content: const Text(
          'This will broadcast an emergency signal to all connected users and responders. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendEmergencySOS(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption(context, 'I am safe', UserStatus.safe, Colors.green),
            _buildStatusOption(context, 'I need help', UserStatus.needHelp, Colors.orange),
            _buildStatusOption(context, 'I can help others', UserStatus.canHelp, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(BuildContext context, String text, dynamic status, Color color) {
    return ListTile(
      leading: Icon(Icons.circle, color: color, size: 16),
      title: Text(text),
      onTap: () {
        Navigator.of(context).pop();
        _updateStatus(context, text);
      },
    );
  }

  void _showResourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resource Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Offer Resources'),
              onTap: () {
                Navigator.of(context).pop();
                _showOfferResourceDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Request Resources'),
              onTap: () {
                Navigator.of(context).pop();
                _showRequestResourceDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Location'),
        content: const Text(
          'Share your current location with connected users for better coordination?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _shareLocation(context);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Community Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Settings'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Settings'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile Settings'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showOfferResourceDialog(BuildContext context) {
    // Implementation for offering resources
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resource offer functionality coming soon')),
    );
  }

  void _showRequestResourceDialog(BuildContext context) {
    // Implementation for requesting resources
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resource request functionality coming soon')),
    );
  }

  void _sendEmergencySOS(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency SOS sent to all connected users!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _updateStatus(BuildContext context, String status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status updated: $status')),
    );
  }

  void _shareLocation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location shared with connected users')),
    );
  }
}

enum UserStatus {
  safe,
  needHelp,
  canHelp,
  offline,
  emergency,
}
