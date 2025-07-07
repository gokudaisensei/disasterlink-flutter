import 'package:flutter_modular/flutter_modular.dart';
import '../../../modules/bluetooth/presentation/stores/real_bluetooth_store.dart';

/// A service class to manage the application-wide Bluetooth functionality.
/// This ensures the Bluetooth module persists even when navigating away from the Bluetooth page.
class BluetoothService {
  /// Initialize the Bluetooth store if it hasn't been initialized yet.
  /// This should be called at app startup.
  static void initializeBluetoothStore() {
    // The store is registered in the AppModule
    try {
      final store = Modular.get<dynamic>(key: 'BluetoothStore');
      if (store != null && store.isInitialized == false) {
        store.initialize();
      }
    } catch (e) {
      print('Error initializing Bluetooth store: $e');
    }
  }

  /// Get the current instance of the BluetoothStore.
  /// The store is a singleton registered in the AppModule.
  static dynamic getBluetoothStore() {
    try {
      return Modular.get<dynamic>(key: 'BluetoothStore');
    } catch (e) {
      print('Error getting Bluetooth store: $e');
      return null;
    }
  }

  /// Get the current Bluetooth connection status.
  /// This can be used to show status indicators in the UI.
  static bool isBluetoothActive() {
    try {
      final store = getBluetoothStore();
      return store != null && store.isInitialized == true && store.isBluetoothEnabled == true;
    } catch (e) {
      return false;
    }
  }
}
