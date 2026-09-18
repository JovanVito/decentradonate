import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/service_providers.dart';
import '../../data/repositories/donation_repository_impl.dart';
import '../../domain/repositories/donation_repository.dart';

final donationRepositoryProvider = Provider<DonationRepository>((ref) {
  return DonationRepositoryImpl(
    ref.watch(walletServiceProvider),
    web3Service: ref.watch(web3ServiceProvider),
  );
});

/// State `AsyncNotifier<String?>` di sini punya arti KHUSUS (beda dari
/// pola wallet): `null` = belum ada donasi yang dicoba di sesi ini (idle),
/// bukan "sudah donasi tapi hasilnya kosong". Setelah sukses/gagal
/// ditampilkan ke user (lewat dialog/snackbar di UI), panggil `reset()`
/// supaya notifier kembali ke idle dan siap dipakai untuk donasi
/// berikutnya tanpa membawa hash transaksi lama.
class DonationNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<void> donate({required int campaignId, required double amountInMatic}) async {
    state = const AsyncLoading();
    final result = await ref.read(donationRepositoryProvider).donate(
          campaignId: campaignId,
          amountInMatic: amountInMatic,
        );
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (txHash) => AsyncData(txHash),
    );
  }

  void reset() => state = const AsyncData(null);
}

final donationProvider = AsyncNotifierProvider<DonationNotifier, String?>(DonationNotifier.new);
