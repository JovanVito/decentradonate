import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Bottom navigation reusable, dikendalikan oleh go_router lewat
/// StatefulShellRoute (lihat app_router.dart). Widget ini TIDAK menyimpan
/// state navigasi sendiri — cuma "dumb" UI yang melapor index ke parent.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      indicatorColor: AppColors.primary.withOpacity(0.15),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explorer'),
      ],
    );
  }
}
