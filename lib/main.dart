import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'app/app_module.dart';
import 'app/app_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Create the app
  final app = ModularApp(module: AppModule(), child: const AppWidget());

  // Initialize Bluetooth after the first frame to ensure it persists
  // even when navigating away from the Bluetooth page
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // The BluetoothStore is registered in AppModule as a singleton
    // This ensures that once we navigate to the Bluetooth page once,
    // the store will stay initialized even when returning to the Home page
  });

  runApp(app);
}
