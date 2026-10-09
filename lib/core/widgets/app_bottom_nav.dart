import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Navigasi bawah gaya "Riak": pil tinta hutan, aksen saga saat aktif.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showProof;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.showProof,
  });

  @override
  Widget build(BuildContext context) {
    final destinations = <NavigationDestination>[
      const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Beranda'),
      const NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'Riwayat'),
      const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Wallet'),
      if (showProof)
        const NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Bukti'),
      const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil'),
    ];

    return Container(
      color: AppColors.paper,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 64,
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          indicatorColor: AppColors.ripple,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          indicatorShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          destinations: destinations,
        ),
      ),
    );
  }
}
