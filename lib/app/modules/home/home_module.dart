import 'package:flutter_modular/flutter_modular.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/stores/home_store.dart';

class HomeModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<HomeStore>(HomeStore.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const HomePage());
  }
}
