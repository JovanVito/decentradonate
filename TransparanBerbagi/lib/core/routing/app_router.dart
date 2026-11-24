import 'dart:async';

import 'package:decentradonate/features/access/data/supabase_access_repository.dart';
import 'package:decentradonate/features/access/domain/access_repository.dart';
import 'package:decentradonate/features/access/presentation/access_screen.dart';
import 'package:decentradonate/features/access/presentation/sign_in_screen.dart';
import 'package:decentradonate/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final repository = ref.watch(accessRepositoryProvider);
  final refresh = ValueNotifier<int>(0);
  final subscription = repository?.sessionChanges.listen(
    (_) => refresh.value++,
    onError: (Object _) => refresh.value++,
  );
  final router = GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) async {
      final requiredRole = switch (state.uri.path) {
        '/akun/donatur' => AccountRole.donor,
        '/akun/penyelenggara' => AccountRole.organizer,
        _ => null,
      };
      if (requiredRole == null) {
        if (state.uri.path != '/' || repository == null) return null;
        try {
          return switch (await repository.currentRole()) {
            AccountRole.donor => '/akun/donatur',
            AccountRole.organizer => '/akun/penyelenggara',
            _ => null,
          };
        } on Exception {
          return null;
        }
      }
      try {
        if (await repository?.currentRole() == requiredRole) return null;
      } on Exception {
        // Fail closed when the profile cannot be checked.
      }
      return requiredRole == AccountRole.organizer
          ? '/masuk/penyelenggara'
          : '/masuk/donatur';
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const AccessScreen()),
      GoRoute(
        path: '/masuk/donatur',
        builder: (_, _) => const SignInScreen(isOrganizer: false),
      ),
      GoRoute(
        path: '/masuk/penyelenggara',
        builder: (_, _) => const SignInScreen(isOrganizer: true),
      ),
      GoRoute(
        path: '/akun/donatur',
        builder: (_, _) => const _AccountScreen(isOrganizer: false),
      ),
      GoRoute(
        path: '/akun/penyelenggara',
        builder: (_, _) => const _AccountScreen(isOrganizer: true),
      ),
    ],
    errorBuilder: (_, _) => const AccessScreen(),
  );
  ref.onDispose(() {
    if (subscription != null) unawaited(subscription.cancel());
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _AccountScreen extends ConsumerStatefulWidget {
  const _AccountScreen({required this.isOrganizer});

  final bool isOrganizer;

  @override
  ConsumerState<_AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<_AccountScreen> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await ref.read(accessRepositoryProvider)?.signOut();
      if (mounted) context.go('/');
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.accessError)),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isOrganizer ? strings.organizerTitle : strings.donorTitle,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              widget.isOrganizer
                  ? strings.organizerApproved
                  : strings.emailVerified,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _signingOut ? null : _signOut,
              child: Text(strings.signOut),
            ),
          ],
        ),
      ),
    );
  }
}
