import 'package:go_router/go_router.dart';
import '../../features/campaign/domain/entities/campaign.dart';
import '../../features/campaign/presentation/screens/campaign_detail_screen.dart';
import '../../features/campaign/presentation/screens/home_screen.dart';
import '../../features/explorer/presentation/screens/explorer_screen.dart';
import '../../features/proof_of_impact/presentation/screens/upload_proof_screen.dart';
import '../../features/wallet/presentation/screens/backup_mnemonic_screen.dart';
import '../../features/wallet/presentation/screens/import_wallet_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import 'app_shell.dart';

/// Satu-satunya sumber kebenaran untuk semua rute di aplikasi.
///
/// KENAPA go_router (bukan Navigator.push biasa)?
/// 1. Deep-linking: kalau nanti share link kampanye lewat WhatsApp,
///    go_router bisa langsung buka halaman detail yang benar.
/// 2. StatefulShellRoute menjaga 4 tab utama (Home/Explorer/Wallet/Proof)
///    punya bottom nav persisten TANPA kehilangan state saat pindah tab.
/// 3. Type-safe navigation dengan `extra` untuk mengirim object
///    (mis. Campaign) antar halaman tanpa refetch.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'campaign/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final campaign = state.extra is Campaign ? state.extra as Campaign : null;
                  return CampaignDetailScreen(campaignId: id, campaign: campaign);
                },
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/explorer',
            builder: (context, state) => const ExplorerScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/wallet',
            builder: (context, state) => const WalletScreen(),
            routes: [
              GoRoute(
                path: 'backup',
                builder: (context, state) => BackupMnemonicScreen(mnemonic: state.extra as String),
              ),
              GoRoute(
                path: 'import',
                builder: (context, state) => const ImportWalletScreen(),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/upload-proof', builder: (context, state) => const UploadProofScreen()),
        ]),
      ],
    ),
  ],
);
