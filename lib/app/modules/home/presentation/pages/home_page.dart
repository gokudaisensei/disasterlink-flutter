import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../components/greeting_header.dart';
import '../components/location_section.dart';
import '../components/quick_action_card.dart';
import '../components/community_feed.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentLocation = 'Fetching location...';
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = 'Location services are disabled';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = 'Location permissions are denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Location permissions are permanently denied';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String city = placemarks.first.locality ?? 'Unknown city';

      setState(() {
        _currentLocation = city;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _currentLocation = 'Error fetching location';
      });
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
          'DisasterLink',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Row(
            children: [
              Text(
                'Mesh active',
                style: textTheme.bodySmall?.copyWith(color: Colors.green),
              ),
              const SizedBox(width: 4),
              Icon(Icons.language, color: colorScheme.onPrimaryContainer),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GreetingHeader(),
            const SizedBox(height: 16),
            LocationSection(
              location: _currentLocation,
              lastUpdated: _lastUpdated,
              isDarkMode: isDarkMode,
              onUpdate: _fetchLocation,
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                QuickActionCard(
                  title: 'Send Message',
                  icon: Icons.message,
                  isDarkMode: isDarkMode,
                ),
                QuickActionCard(
                  title: 'Broadcast SOS',
                  icon: Icons.warning,
                  isDarkMode: isDarkMode,
                ),
                QuickActionCard(
                  title: 'Report Resource Need',
                  icon: Icons.report,
                  isDarkMode: isDarkMode,
                ),
                QuickActionCard(
                  title: 'Share My Status',
                  icon: Icons.share,
                  isDarkMode: isDarkMode,
                ),
                QuickActionCard(
                  title: 'Nearby Alerts',
                  icon: Icons.notifications,
                  isDarkMode: isDarkMode,
                ),
                QuickActionCard(
                  title: 'Bluetooth Mesh',
                  icon: Icons.bluetooth,
                  isDarkMode: isDarkMode,
                  onTap: () => Modular.to.pushNamed('/bluetooth/'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Community Feed',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CommunityFeed(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new community feed
        },
        backgroundColor: colorScheme.secondary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
