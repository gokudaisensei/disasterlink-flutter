import 'package:flutter_modular/flutter_modular.dart';
import 'presentation/pages/bluetooth_page.dart';

class BluetoothModule extends Module {
  @override
  void binds(Injector i) {
    // BluetoothStore is now bound in AppModule for persistence
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const BluetoothPage());
  }
}
