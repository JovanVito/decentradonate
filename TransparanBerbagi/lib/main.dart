import 'package:decentradonate/features/access/data/secure_session_storage.dart';
import 'package:decentradonate/features/campaigns/data/campaign_repository.dart';
import 'package:decentradonate/features/access/data/supabase_access_repository.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:decentradonate/core/config/app_config.dart';
import 'package:decentradonate/core/routing/app_router.dart';
import 'package:decentradonate/core/theme/app_theme.dart';
import 'package:decentradonate/l10n/app_localizations.dart';

const _localizationDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SupabaseAccessRepository? repository;
  CampaignRepository? campaigns;
  try {
    final config = AppConfig.fromDefines()..validate();
    if (!config.isPreview) {
      await Supabase.initialize(
        url: config.supabaseUrl,
        publishableKey: config.supabasePublishableKey,
        debug: false,
        authOptions: FlutterAuthClientOptions(
          detectSessionInUri: false,
          localStorage: SecureSessionStorage(Uri.parse(config.supabaseUrl)),
        ),
      );
      repository = SupabaseAccessRepository(Supabase.instance.client);
      campaigns = CampaignRepository(Supabase.instance.client);
    }
  } on Object {
    runApp(const SetupErrorApp());
    return;
  }
  runApp(
    ProviderScope(
      overrides: [
        accessRepositoryProvider.overrideWithValue(repository),
        campaignRepositoryProvider.overrideWithValue(campaigns),
      ],
      child: const DecentradonateApp(),
    ),
  );
}

class DecentradonateApp extends ConsumerWidget {
  const DecentradonateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConfig.name,
      localizationsDelegates: _localizationDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class SetupErrorApp extends StatelessWidget {
  const SetupErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.name,
      localizationsDelegates: _localizationDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(AppLocalizations.of(context)!.setupError),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
