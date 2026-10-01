import 'package:dartz/dartz.dart';
import 'package:decentradonate/core/errors/failures.dart';
import 'package:decentradonate/features/campaign/data/repositories/campaign_repository_impl.dart';
import 'package:decentradonate/features/campaign/domain/entities/campaign.dart';
import 'package:decentradonate/features/campaign/domain/repositories/campaign_repository.dart';
import 'package:decentradonate/features/campaign/presentation/providers/campaign_list_provider.dart';
import 'package:decentradonate/features/campaign/presentation/screens/home_screen.dart';
import 'package:decentradonate/features/donation/domain/repositories/donation_repository.dart';
import 'package:decentradonate/features/donation/presentation/providers/donation_providers.dart';
import 'package:decentradonate/features/donation/presentation/widgets/donate_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCampaignRepository implements CampaignRepository {
  FakeCampaignRepository({
    this.delay = Duration.zero,
    this.shouldFail = false,
    this.returnEmpty = false,
  });

  final Duration delay;
  bool shouldFail;
  final bool returnEmpty;
  int callCount = 0;

  @override
  Future<Either<Failure, List<Campaign>>> getCampaigns() async {
    callCount++;
    await Future.delayed(delay);
    if (shouldFail) {
      return const Left(
        NetworkFailure('Gagal memuat kampanye. Periksa koneksi lalu coba lagi.'),
      );
    }
    if (returnEmpty) return const Right(<Campaign>[]);
    return Right(dummyCampaigns());
  }
}

class FakeDonationRepository implements DonationRepository {
  FakeDonationRepository({
    this.delay = Duration.zero,
    this.shouldFail = false,
  });

  final Duration delay;
  final bool shouldFail;
  int callCount = 0;

  @override
  Future<Either<Failure, String>> donate({
    required int campaignId,
    required double amountInMatic,
  }) async {
    callCount++;
    await Future.delayed(delay);
    if (shouldFail) {
      return const Left(TransactionFailure('Saldo tidak cukup untuk donasi.'));
    }
    return const Right('0xabc123hash');
  }
}

Widget wrapWithScope({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

Widget wrapSheet({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

void main() {
  group('validateDonationAmount', () {
    test('kosong ditolak', () {
      expect(validateDonationAmount(''), 'Nominal wajib diisi');
      expect(validateDonationAmount('   '), 'Nominal wajib diisi');
    });

    test('bukan angka ditolak', () {
      expect(validateDonationAmount('abc'), 'Masukkan angka yang valid');
    });

    test('nol dan negatif ditolak', () {
      expect(validateDonationAmount('0'), 'Nominal harus lebih dari 0');
      expect(validateDonationAmount('-1'), 'Nominal harus lebih dari 0');
    });

    test('di bawah minimal ditolak', () {
      expect(validateDonationAmount('0.0005'), 'Minimal donasi 0,001');
    });

    test('nilai wajar diterima', () {
      expect(validateDonationAmount('0.01'), isNull);
      expect(validateDonationAmount('1,5'), isNull);
    });
  });

  testWidgets('1 - initial loading tampil saat repository lambat',
      (tester) async {
    final fake = FakeCampaignRepository(delay: const Duration(seconds: 2));
    await tester.pumpWidget(wrapWithScope(
      child: const HomeScreen(),
      overrides: [campaignRepositoryProvider.overrideWithValue(fake)],
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.pumpAndSettle();
  });

  testWidgets('2 - data berhasil dimuat tampil sebagai daftar',
      (tester) async {
    final fake = FakeCampaignRepository();
    await tester.pumpWidget(wrapWithScope(
      child: const HomeScreen(),
      overrides: [campaignRepositoryProvider.overrideWithValue(fake)],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Bantu Renovasi Sekolah Darurat di Cianjur'),
        findsWidgets);
    expect(fake.callCount, 1);
  });

  testWidgets('3 - empty state saat list kosong', (tester) async {
    final fake = FakeCampaignRepository(returnEmpty: true);
    await tester.pumpWidget(wrapWithScope(
      child: const HomeScreen(),
      overrides: [campaignRepositoryProvider.overrideWithValue(fake)],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada kampanye'), findsOneWidget);
  });

  testWidgets('4 - error state dengan retry yang berhasil', (tester) async {
    final fake = FakeCampaignRepository(shouldFail: true);
    await tester.pumpWidget(wrapWithScope(
      child: const HomeScreen(),
      overrides: [campaignRepositoryProvider.overrideWithValue(fake)],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Gagal memuat kampanye'), findsOneWidget);

    fake.shouldFail = false;
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Bantu Renovasi Sekolah Darurat di Cianjur'),
        findsWidgets);
    expect(fake.callCount, greaterThanOrEqualTo(2));
  });

  testWidgets('5 - validasi form menolak input kosong', (tester) async {
    await tester.pumpWidget(wrapSheet(
      child: const DonateBottomSheet(campaignId: 0, campaignTitle: 'Demo'),
      overrides: [
        donationRepositoryProvider
            .overrideWithValue(FakeDonationRepository()),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '');
    await tester.tap(find.text('Kirim Donasi'));
    await tester.pump();

    expect(find.text('Nominal wajib diisi'), findsOneWidget);
  });

  testWidgets('6 - submit loading cegah double tap', (tester) async {
    final fake =
        FakeDonationRepository(delay: const Duration(milliseconds: 500));
    await tester.pumpWidget(wrapSheet(
      child: const DonateBottomSheet(campaignId: 0, campaignTitle: 'Demo'),
      overrides: [donationRepositoryProvider.overrideWithValue(fake)],
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '0.05');
    await tester.tap(find.text('Kirim Donasi'));
    await tester.pump();
    // Tap kedua saat masih loading harus diabaikan oleh guard + tombol disabled.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.pumpAndSettle();
    expect(fake.callCount, 1);
  });

  testWidgets('7 - donasi sukses tampilkan dialog hash', (tester) async {
    await tester.pumpWidget(wrapSheet(
      child: const DonateBottomSheet(campaignId: 0, campaignTitle: 'Demo'),
      overrides: [
        donationRepositoryProvider
            .overrideWithValue(FakeDonationRepository()),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '0.02');
    await tester.tap(find.text('Kirim Donasi'));
    await tester.pumpAndSettle();

    expect(find.text('Donasi Terkirim'), findsOneWidget);
    expect(find.textContaining('0xabc123hash'), findsOneWidget);
  });

  testWidgets('8 - donasi gagal tampilkan pesan tanpa tutup sheet',
      (tester) async {
    await tester.pumpWidget(wrapSheet(
      child: const DonateBottomSheet(campaignId: 0, campaignTitle: 'Demo'),
      overrides: [
        donationRepositoryProvider
            .overrideWithValue(FakeDonationRepository(shouldFail: true)),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '0.02');
    await tester.tap(find.text('Kirim Donasi'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Saldo tidak cukup'), findsOneWidget);
    // Sheet tidak tertutup: tombol kirim masih ada.
    expect(find.text('Kirim Donasi'), findsOneWidget);
  });

  test('repository impl default kembalikan dummy', () async {
    const repo = CampaignRepositoryImpl(delay: Duration.zero);
    final result = await repo.getCampaigns();
    expect(result.isRight(), isTrue);
  });
}
