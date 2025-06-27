class AppColors {
  static const primary = 0xFF1565C0; // Blue 800 (matches app bar, FAB, buttons)
  static const primaryLight =
      0xFF42A5F5; // Blue 400 (lighter blue for highlights)
  static const primaryDark = 0xFF003c8f; // Blue 900 (darker blue)

  static const secondary = 0xFF00B8D4; // Cyan A400 (for accents if needed)
  static const secondaryLight = 0xFF62efff; // Cyan A100
  static const secondaryDark = 0xFF008ba3; // Cyan 700

  static const success = 0xFF388E3C; // Green 700 (unchanged)
  static const warning = 0xFFF57C00; // Orange 700 (unchanged)
  static const error = 0xFFD32F2F; // Red 700 (for SOS, unchanged)
  static const info = 0xFF1976D2; // Blue 700 (for info, unchanged)

  static const textPrimary = 0xFF212121; // Grey 900 (almost black)
  static const textSecondary = 0xFF757575; // Grey 600
  static const textDisabled = 0xFFBDBDBD; // Grey 400

  static const background = 0xFFFFFFFF; // White (main background)
  static const surface = 0xFFF5F5F5; // Grey 100 (card/feed background)
  static const surfaceVariant =
      0xFFF0F4F8; // Very light blue/grey (for subtle surfaces)
}

class AppConstants {
  static const String appName = 'DisasterLink';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://api.disasterlink.com';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String settingsKey = 'app_settings';

  // Emergency Contact Numbers
  static const Map<String, String> emergencyContacts = {
    'Police': '100',
    'Fire': '101',
    'Ambulance': '108',
    'Disaster Management': '1077',
    'Women Helpline': '1091',
  };
}

class AppStrings {
  static const String loading = 'Loading...';
  static const String error = 'Something went wrong';
  static const String networkError = 'Network connection error';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String ok = 'OK';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String sort = 'Sort';
  static const String refresh = 'Refresh';

  // Emergency Strings
  static const String reportEmergency = 'Report Emergency';
  static const String findShelter = 'Find Shelter';
  static const String emergencyContacts = 'Emergency Contacts';
  static const String safetyTips = 'Safety Tips';
  static const String currentStatus = 'Current Status';
  static const String allClear = 'All Clear';
  static const String recentAlerts = 'Recent Alerts';
  static const String noRecentAlerts = 'No recent alerts';
}
