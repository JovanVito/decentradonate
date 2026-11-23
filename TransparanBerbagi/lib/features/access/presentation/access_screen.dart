import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:transparan_berbagi/core/config/app_config.dart';
import 'package:transparan_berbagi/l10n/app_localizations.dart';

class AccessScreen extends StatelessWidget {
  const AccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.volunteer_activism_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(AppConfig.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(strings.accessDescription),
                  const SizedBox(height: 32),
                  Text(strings.accessTitle, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/masuk/donatur'),
                    child: Text(strings.donorEntry),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/masuk/penyelenggara'),
                    child: Text(strings.organizerEntry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PendingAccessScreen extends StatelessWidget {
  const PendingAccessScreen({required this.isOrganizer, super.key});

  final bool isOrganizer;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(isOrganizer ? strings.organizerTitle : strings.donorTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(strings.otpUnavailable),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.go('/'),
            child: Text(strings.returnToAccess),
          ),
        ],
      ),
    );
  }
}
