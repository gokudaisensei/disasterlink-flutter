import 'package:flutter_modular/flutter_modular.dart';
import 'modules/home/home_module.dart';
import 'modules/bluetooth/bluetooth_module.dart';
import 'modules/community/community_module.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {
    // Global dependencies and services go here
  }

  @override
  void routes(RouteManager r) {
    r.module('/', module: HomeModule());
    r.module('/bluetooth', module: BluetoothModule());
    r.module('/community', module: CommunityModule());
  }
}
