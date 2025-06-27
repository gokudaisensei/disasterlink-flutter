import 'package:flutter/material.dart';

class LocationSection extends StatelessWidget {
  final String location;
  final DateTime? lastUpdated;
  final bool isDarkMode;
  final VoidCallback onUpdate;

  const LocationSection({
    super.key,
    required this.location,
    required this.lastUpdated,
    required this.isDarkMode,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            if (lastUpdated != null)
              Text(
                'Last updated: \t${lastUpdated!.toLocal()}'.split('.')[0],
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: colorScheme.primary),
          onPressed: onUpdate,
        ),
      ],
    );
  }
}
