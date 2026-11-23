import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transparan_berbagi/core/config/app_config.dart';
import 'package:transparan_berbagi/core/routing/app_router.dart';
import 'package:transparan_berbagi/core/theme/app_theme.dart';
import 'package:transparan_berbagi/l10n/app_localizations.dart';

const _localizationDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final config = AppConfig.fromDefines()..validate();
    if (!config.isPreview) {
      await Supabase.initialize(
        url: config.supabaseUrl,
        publishableKey: config.supabasePublishableKey,
        debug: false,
      );
    }
  } on Object {
    runApp(const SetupErrorApp());
    return;
  }
  runApp(const ProviderScope(child: TransparanBerbagiApp()));
}

class TransparanBerbagiApp extends ConsumerWidget {
  const TransparanBerbagiApp({super.key});

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
