import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_bottom_nav.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final showProof = profile.valueOrNull?.isOrganizer ?? false;
    final visibleIndex = showProof || navigationShell.currentIndex < 3
        ? navigationShell.currentIndex
        : navigationShell.currentIndex == 4
            ? 3
            : navigationShell.currentIndex;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: visibleIndex,
        showProof: showProof,
        onTap: (index) {
          final branchIndex = showProof || index < 3 ? index : 4;
          navigationShell.goBranch(
            branchIndex,
            initialLocation: branchIndex == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
