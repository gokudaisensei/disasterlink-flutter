import 'package:flutter_modular/flutter_modular.dart';
import 'modules/home/home_module.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {
    // Global dependencies and services go here
  }

  @override
  void routes(RouteManager r) {
    r.module('/', module: HomeModule());
  }
}
