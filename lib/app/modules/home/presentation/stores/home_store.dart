import 'package:flutter/foundation.dart';

class HomeStore extends ChangeNotifier {
  String _selectedAlert = '';
  final List<Map<String, dynamic>> _recentAlerts = [
    {
      'title': 'Flood Warning',
      'location': 'Downtown Area',
      'severity': 'High',
      'time': '2 mins ago',
      'icon': '🌊',
    },
    {
      'title': 'Earthquake Alert',
      'location': 'Northern District',
      'severity': 'Medium',
      'time': '15 mins ago',
      'icon': '🏠',
    },
    {
      'title': 'Storm Warning',
      'location': 'Coastal Region',
      'severity': 'High',
      'time': '1 hour ago',
      'icon': '⛈️',
    },
  ];

  String get selectedAlert => _selectedAlert;
  List<Map<String, dynamic>> get recentAlerts => _recentAlerts;

  void selectAlert(String alert) {
    _selectedAlert = alert;
    notifyListeners();
  }

  void addAlert(Map<String, dynamic> alert) {
    _recentAlerts.insert(0, alert);
    notifyListeners();
  }

  void clearAlerts() {
    _recentAlerts.clear();
    notifyListeners();
  }
}
