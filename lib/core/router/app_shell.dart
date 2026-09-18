import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_bottom_nav.dart';

/// Shell yang membungkus Home / Wallet / Upload Proof dengan satu
/// bottom navigation yang persisten. `StatefulShellRoute` (go_router)
/// menjaga state tiap tab tetap hidup saat berpindah tab (mis. scroll
/// position di Home tidak reset saat pindah ke Wallet lalu balik lagi).
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
