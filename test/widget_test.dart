import 'package:donasi_transparan/local_notes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:donasi_transparan/donation_amount.dart';
import 'package:donasi_transparan/campaign.dart';
import 'package:donasi_transparan/local_repository.dart';
import 'package:donasi_transparan/password_reset.dart';
import 'package:donasi_transparan/wallet_community.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({'donasi_note_examples_added': true}));

  test('LocalNote model serializes and restores', () {
    final note = LocalNote(id: '1', title: 'Donasi', content: 'Bantuan', updatedAt: DateTime.utc(2026, 1, 1));
    final restored = LocalNote.fromJson(note.toJson());
    expect(restored.id, '1');
    expect(restored.title, 'Donasi');
    expect(restored.content, 'Bantuan');
    expect(restored.updatedAt, note.updatedAt);
  });

  test('Notes persist across controllers and support create, update, delete', () async {
    final controller = LocalNotesController(LocalNoteRepository());
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.loading, isFalse);
    expect(controller.notes, isEmpty);

    final save = controller.save(title: ' Dana ', content: ' Catatan ');
    expect(controller.saving, isTrue);
    await save;
    expect(controller.saving, isFalse);
    final note = controller.notes.single;
    expect(note.title, 'Dana');

    final reopened = LocalNotesController(LocalNoteRepository());
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(reopened.notes.single.content, 'Catatan');
    await reopened.save(id: note.id, title: 'Diperbarui', content: note.content);
    expect(reopened.notes.single.id, note.id);
    expect(reopened.notes.single.title, 'Diperbarui');
    await reopened.remove(note.id);
    expect(await LocalNoteRepository().readAll(), isEmpty);
  });

  test('Blank titles and content are rejected', () async {
    final controller = LocalNotesController(LocalNoteRepository());
    addTearDown(controller.dispose);
    await expectLater(controller.save(title: ' ', content: 'Isi'), throwsFormatException);
    await expectLater(controller.save(title: 'Judul', content: ' '), throwsFormatException);
    expect(controller.saving, isFalse);
  });

  test('Failed load can be retried after local data is repaired', () async {
    SharedPreferences.setMockInitialValues({'donasi_local_notes': ['invalid json']});
    final controller = LocalNotesController(LocalNoteRepository());
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.loading, isFalse);
    expect(controller.error, isNotNull);
    await (await SharedPreferences.getInstance()).clear();
    await controller.load();
    expect(controller.error, isNull);
    expect(controller.notes, isEmpty);
  });

  testWidgets('Notes page validates, saves, reloads, and deletes a note', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LocalNotesPage()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada catatan'), findsOneWidget);

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Judul wajib diisi'), findsOneWidget);
    expect(find.text('Isi wajib diisi'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Penyaluran');
    await tester.enterText(find.byType(TextFormField).at(1), 'Lima paket');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Penyaluran'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: LocalNotesPage()));
    await tester.pumpAndSettle();
    expect(find.text('Lima paket'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada catatan'), findsOneWidget);
  });

  testWidgets('Notes page shows a retry action when local data is invalid', (tester) async {
    SharedPreferences.setMockInitialValues({
      'donasi_note_examples_added': true,
      'donasi_local_notes': ['invalid json'],
    });
    await tester.pumpWidget(const MaterialApp(home: LocalNotesPage()));
    await tester.pumpAndSettle();
    expect(find.text('Data lokal gagal dibaca'), findsOneWidget);

    await (await SharedPreferences.getInstance()).remove('donasi_local_notes');
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada catatan'), findsOneWidget);
  });

  test('Example notes are added once and stay deleted after reopening', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalNoteRepository(includeExamples: true);
    final examples = await repository.readAll();
    expect(examples, hasLength(4));
    await repository.delete(examples.first.id);
    final reopened = await LocalNoteRepository(includeExamples: true).readAll();
    expect(reopened, hasLength(3));
    expect(reopened.map((note) => note.id), isNot(contains(examples.first.id)));
  });

  test('All ten campaign photos are bundled as distinct JPEGs', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final photos = manifest.listAssets().where((asset) => asset.startsWith('assets/campaigns/') && asset.endsWith('.jpg'));
    expect(photos, hasLength(10));
    for (final path in photos) {
      final image = await rootBundle.load(path);
      expect(image.getUint16(0), 0xffd8);
    }
  });

  testWidgets('Top up requires selecting one of the three demo methods', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TopupMethodPage(amount: 50000)));
    final confirm = find.widgetWithText(FilledButton, 'Tambah saldo');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(find.text('QRIS'), findsOneWidget);
    expect(find.text('Transfer bank'), findsOneWidget);
    await tester.tap(find.text('E-wallet'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
  });

  testWidgets('Forum keeps adding conversation and refreshing posts', (tester) async {
    var loads = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CommunityPage(
      loadPosts: () async {
        loads++;
        return [];
      },
    ))));
    expect(find.text('Tulis di forum'), findsOneWidget);
    expect(find.text('Mika Ranu'), findsNothing);
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Mika Ranu'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Dira Lazuardi'), findsOneWidget);
    expect(loads, greaterThan(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Donation sheet offers presets and validates a custom amount', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: DonationAmountSheet())));
    expect(find.text('Rp 5.000'), findsOneWidget);
    expect(find.text('Rp 100.000'), findsOneWidget);
    await tester.tap(find.text('Rp 25.000'));
    await tester.pump();
    expect(find.text('Donasi Rp 25.000'), findsOneWidget);
    await tester.tap(find.text('Nominal lain'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '4999');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '12500');
    await tester.pump();
    expect(find.text('Donasi Rp 12.500'), findsOneWidget);
  });

  testWidgets('Recovery form validates password length and confirmation', (tester) async {
    await tester.pumpWidget(MaterialApp(home: PasswordRecoveryPage(onComplete: () {})));
    final password = find.byType(TextFormField).at(0);
    final confirmation = find.byType(TextFormField).at(1);
    await tester.enterText(password, 'short');
    await tester.enterText(confirmation, 'different');
    await tester.tap(find.text('Simpan kata sandi'));
    await tester.pumpAndSettle();
    expect(find.text('Gunakan minimal 8 karakter.'), findsOneWidget);
    expect(find.text('Kedua kata sandi harus sama.'), findsOneWidget);
  });

  testWidgets('Campaign publishing form offers an optional cover photo', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateCampaign()));
    expect(find.text('Pilih foto campaign'), findsOneWidget);
    expect(find.text('Hapus foto'), findsNothing);
  });
}
