import 'package:flutter_modular/flutter_modular.dart';
import 'presentation/pages/bluetooth_page.dart';
import 'presentation/stores/bluetooth_store.dart';

class BluetoothModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<BluetoothStore>(BluetoothStore.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const BluetoothPage());
  }
}
