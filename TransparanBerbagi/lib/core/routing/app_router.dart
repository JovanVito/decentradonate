import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:decentradonate/features/access/presentation/access_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const AccessScreen()),
      GoRoute(
        path: '/masuk/donatur',
        builder: (_, _) => const PendingAccessScreen(isOrganizer: false),
      ),
      GoRoute(
        path: '/masuk/penyelenggara',
        builder: (_, _) => const PendingAccessScreen(isOrganizer: true),
      ),
    ],
    errorBuilder: (_, _) => const AccessScreen(),
  );
  ref.onDispose(router.dispose);
  return router;
});
