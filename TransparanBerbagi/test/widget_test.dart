import 'package:decentradonate/features/access/data/supabase_access_repository.dart';
import 'package:decentradonate/features/access/domain/access_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:decentradonate/core/config/app_config.dart';
import 'package:decentradonate/main.dart';

void main() {
  testWidgets('organizer entry shows its own access screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DecentradonateApp()));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Relawan memilah barang ke dalam kotak donasi'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Masuk sebagai Penyelenggara'));
    await tester.tap(find.text('Masuk sebagai Penyelenggara'));
    await tester.pumpAndSettle();
    expect(find.text('Akses penyelenggara'), findsOneWidget);

    await tester.tap(find.text('Kembali ke pilihan akses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk sebagai Donatur'));
    await tester.pumpAndSettle();
    expect(find.text('Akses donatur'), findsOneWidget);
  });

  testWidgets('donor OTP cannot unlock organizer account', (tester) async {
    final repository = _TestAccessRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [accessRepositoryProvider.overrideWithValue(repository)],
        child: const DecentradonateApp(),
      ),
    );
    await tester.pumpAndSettle();
    final organizerEntry = find.text('Masuk sebagai Penyelenggara');
    await tester.ensureVisible(organizerEntry);
    await tester.tap(organizerEntry);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'donor@example.com');
    await tester.tap(find.text('Kirim kode'));
    await tester.pumpAndSettle();
    expect(repository.signupAllowed, isFalse);
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Verifikasi dan masuk'));
    await tester.pumpAndSettle();
    expect(
      find.text('Akun ini tidak memiliki akses untuk peran yang dipilih.'),
      findsOneWidget,
    );
    expect(repository.role, isNull);
    await tester.pumpWidget(const SizedBox());
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

class _TestAccessRepository implements AccessRepository {
  AccountRole? role;
  bool? signupAllowed;

  @override
  Stream<void> get sessionChanges => const Stream.empty();

  @override
  Future<AccountRole?> currentRole() async => role;

  @override
  Future<void> sendCode(String email, {required bool allowSignup}) async {
    signupAllowed = allowSignup;
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    role = AccountRole.donor;
  }

  @override
  Future<void> signOut() async {
    role = null;
  }
}
