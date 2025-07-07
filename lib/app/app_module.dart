import 'package:flutter_modular/flutter_modular.dart';
import 'modules/home/home_module.dart';
import 'modules/bluetooth/bluetooth_module.dart';
import 'modules/bluetooth/presentation/stores/real_bluetooth_store.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {
    // Global dependencies and services go here
    i.addSingleton<BluetoothStore>(BluetoothStore.new);
  }

  @override
  void routes(RouteManager r) {
    r.module('/', module: HomeModule());
    r.module('/bluetooth', module: BluetoothModule());
  }
}
