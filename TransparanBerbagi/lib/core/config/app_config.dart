enum AppEnvironment { dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  factory AppConfig.fromDefines() {
    return AppConfig(
      environment: AppEnvironment.values.byName(
        const String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
      ),
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey: const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
      ),
    );
  }

  static const name = 'TransparanBerbagi';

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabasePublishableKey;

  bool get isPreview =>
      environment == AppEnvironment.dev &&
      supabaseUrl.isEmpty &&
      supabasePublishableKey.isEmpty;

  void validate() {
    if (isPreview) return;
    final url = Uri.tryParse(supabaseUrl);
    final secureUrl = url?.scheme == 'https';
    final localUrl =
        environment == AppEnvironment.dev &&
        url?.scheme == 'http' &&
        const {'localhost', '127.0.0.1', '10.0.2.2'}.contains(url?.host);
    if (url == null ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        !(secureUrl || localUrl) ||
        !supabasePublishableKey.startsWith('sb_publishable_')) {
      throw const FormatException('Invalid public Supabase configuration');
    }
  }
}
