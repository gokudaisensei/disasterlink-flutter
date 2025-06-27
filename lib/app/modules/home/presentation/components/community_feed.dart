import 'package:flutter/material.dart';

class CommunityFeed extends StatelessWidget {
  const CommunityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Expanded(
      child: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.warning, color: colorScheme.error),
            title: Text('Injured at Main Rd.', style: textTheme.bodyLarge),
            subtitle: Text('12:05 SOS', style: textTheme.bodySmall),
          ),
          ListTile(
            leading: Icon(Icons.group, color: colorScheme.primary),
            title: Text(
              'Water available at School',
              style: textTheme.bodyLarge,
            ),
            subtitle: Text('12:03 Group', style: textTheme.bodySmall),
          ),
          ListTile(
            leading: Icon(Icons.verified, color: colorScheme.secondary),
            title: Text(
              'Riya marked indoors, Storm alert!',
              style: textTheme.bodyLarge,
            ),
            subtitle: Text('11:01 Official', style: textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
