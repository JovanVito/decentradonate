import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showProof;

  const AppBottomNav(
      {super.key,
      required this.currentIndex,
      required this.onTap,
      required this.showProof});

  @override
  Widget build(BuildContext context) {
    final destinations = <NavigationDestination>[
      const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home'),
      const NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'History'),
      const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Wallet'),
      if (showProof)
        const NavigationDestination(
            icon: Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file),
            label: 'Proof'),
      const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile'),
    ];
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      destinations: destinations,
    );
  }
}
