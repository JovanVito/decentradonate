import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:decentradonate/core/config/app_config.dart';
import 'package:decentradonate/l10n/app_localizations.dart';

class AccessScreen extends StatelessWidget {
  const AccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConfig.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            strings.accessHeadline,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            strings.accessDescription,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(strings.accessTitle, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _AccessOption(
                    icon: Icons.favorite_outline,
                    title: strings.donorEntry,
                    onTap: () => context.push('/masuk/donatur'),
                  ),
                  const SizedBox(height: 8),
                  _AccessOption(
                    icon: Icons.groups_outlined,
                    title: strings.organizerEntry,
                    onTap: () => context.push('/masuk/penyelenggara'),
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

class _AccessOption extends StatelessWidget {
  const _AccessOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minTileHeight: 64,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleMedium),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppConfig.name)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Icon(
                          Icons.mark_email_read_outlined,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isOrganizer
                            ? strings.organizerTitle
                            : strings.donorTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(strings.otpUnavailable),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                        child: Text(strings.returnToAccess),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
