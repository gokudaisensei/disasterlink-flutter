import 'package:flutter_modular/flutter_modular.dart';
import 'presentation/pages/community_page.dart';
import 'presentation/pages/user_discovery_page.dart';
import 'presentation/pages/peer_messaging_page.dart';
import 'presentation/stores/community_store.dart';
import 'presentation/stores/messaging_store.dart';

class CommunityModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<CommunityStore>(CommunityStore.new);
    i.addSingleton<MessagingStore>(MessagingStore.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const CommunityPage());
    r.child('/discovery', child: (context) => const UserDiscoveryPage());
    r.child('/messaging', child: (context) => const PeerMessagingPage());
  }
}
