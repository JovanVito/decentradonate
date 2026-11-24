import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:decentradonate/core/config/app_config.dart';
import 'package:decentradonate/main.dart';

void main() {
  testWidgets('organizer entry shows its own access screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DecentradonateApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Masuk sebagai Penyelenggara'));
    await tester.pumpAndSettle();
    expect(find.text('Akses penyelenggara'), findsOneWidget);

    await tester.tap(find.text('Kembali ke pilihan akses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk sebagai Donatur'));
    await tester.pumpAndSettle();
    expect(find.text('Akses donatur'), findsOneWidget);
  });

  test('production requires configuration even when both fields are blank', () {
    const config = AppConfig(
      environment: AppEnvironment.prod,
      supabaseUrl: '',
      supabasePublishableKey: '',
    );
    expect(config.validate, throwsFormatException);
  });

  test('development can start in preview without credentials', () {
    const config = AppConfig(
      environment: AppEnvironment.dev,
      supabaseUrl: '',
      supabasePublishableKey: '',
    );
    expect(config.isPreview, isTrue);
    expect(config.validate, returnsNormally);
  });
}
