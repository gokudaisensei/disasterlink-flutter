import 'package:flutter_modular/flutter_modular.dart';
import 'presentation/pages/bluetooth_page.dart';
import 'presentation/pages/bluetooth_debug_page.dart';
import 'utils/bluetooth_debug.dart';

class BluetoothModule extends Module {
  @override
  void binds(Injector i) {
    // BluetoothStore is bound in AppModule for persistence
    // Use the existing instance with a safe access pattern
    i.addSingleton(() => BluetoothDebug(Modular.get()));
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const BluetoothPage());
    r.child('/debug', child: (context) => const BluetoothDebugPage());
  }
}
