import 'package:go_router/go_router.dart';
import '../constants/supabase_config.dart';
import '../../features/auth/presentation/screens/auth_screens.dart';
import '../../features/campaign/domain/entities/campaign.dart';
import '../../features/campaign/presentation/screens/campaign_detail_screen.dart';
import '../../features/campaign/presentation/screens/home_screen.dart';
import '../../features/explorer/presentation/screens/explorer_screen.dart';
import '../../features/proof_of_impact/presentation/screens/upload_proof_screen.dart';
import '../../features/profile/presentation/screens/profile_screens.dart';
import '../../features/wallet/presentation/screens/backup_mnemonic_screen.dart';
import '../../features/wallet/presentation/screens/import_wallet_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import 'app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: SupabaseConfig.isConfigured && supabaseClient?.auth.currentSession == null ? '/login' : '/',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/organizer/terms', builder: (_, __) => const OrganizerTermsScreen()),
    GoRoute(path: '/campaign/create', builder: (_, __) => const CreateCampaignScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, __) => const HomeScreen(), routes: [GoRoute(path: 'campaign/:id', builder: (context, state) { final id = state.pathParameters['id']!; final campaign = state.extra is Campaign ? state.extra as Campaign : null; return CampaignDetailScreen(campaignId: id, campaign: campaign); })])]),
        StatefulShellBranch(routes: [GoRoute(path: '/explorer', builder: (_, __) => const ExplorerScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen(), routes: [GoRoute(path: 'backup', builder: (_, state) => BackupMnemonicScreen(mnemonic: state.extra as String)), GoRoute(path: 'import', builder: (_, __) => const ImportWalletScreen())])]),
        StatefulShellBranch(routes: [GoRoute(path: '/upload-proof', builder: (_, __) => const UploadProofScreen())]),
      ],
    ),
  ],
);
