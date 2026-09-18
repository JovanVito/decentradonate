import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/service_providers.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/wallet_info.dart';
import '../../domain/repositories/wallet_repository.dart';

/// CATATAN: kita pakai `AsyncNotifier` bawaan Riverpod TANPA code generation
/// (`@riverpod` annotation). Kenapa? Supaya kamu tidak WAJIB menjalankan
/// `build_runner` untuk fitur ini spesifik — lebih sedikit yang bisa gagal
/// saat kamu pertama kali coba `flutter run` fitur baru ini. Kalau nanti
/// mau migrasi ke versi ber-annotation, logika di dalam TIDAK perlu berubah,
/// cuma boilerplate provider-nya yang beda.

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(
    ref.watch(walletServiceProvider),
    web3Service: ref.watch(web3ServiceProvider),
  );
});

/// `AsyncNotifier<WalletInfo?>` — perhatikan `AsyncValue<T>` bawaan Riverpod
/// SUDAH otomatis punya 3 state: loading/data/error (mirip `ViewState` yang
/// kita buat manual di Stage 1). Bedanya, di sini "empty" direpresentasikan
/// lewat `data == null` (belum ada wallet), bukan varian terpisah — karena
/// datanya memang sesederhana itu (ada wallet atau tidak).
class WalletNotifier extends AsyncNotifier<WalletInfo?> {
  @override
  Future<WalletInfo?> build() async {
    final result = await ref.read(walletRepositoryProvider).getActiveWallet();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (wallet) => wallet,
    );
  }

  /// Return value: mnemonic (untuk ditampilkan SEKALI di layar backup),
  /// atau null kalau gagal. State provider TIDAK menyimpan mnemonic ini.
  Future<String?> createWallet() async {
    state = const AsyncLoading();
    final result = await ref.read(walletRepositoryProvider).createWallet();
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return null;
      },
      (wallet) {
        // Simpan versi TANPA mnemonic ke state permanen.
        state = AsyncData(WalletInfo(address: wallet.address));
        return wallet.mnemonicForBackup;
      },
    );
  }

  Future<bool> importWallet(String mnemonic) async {
    state = const AsyncLoading();
    final result = await ref.read(walletRepositoryProvider).importWallet(mnemonic);
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (wallet) {
        state = AsyncData(wallet);
        return true;
      },
    );
  }

  Future<void> deleteWallet() async {
    state = const AsyncLoading();
    final result = await ref.read(walletRepositoryProvider).deleteWallet();
    result.fold(
      (failure) => state = AsyncError(failure.message, StackTrace.current),
      (_) => state = const AsyncData(null),
    );
  }
}

final walletProvider = AsyncNotifierProvider<WalletNotifier, WalletInfo?>(WalletNotifier.new);

/// Provider terpisah untuk saldo — SENGAJA tidak digabung ke dalam
/// `WalletNotifier.state` supaya keduanya independen: reload saldo (mis.
/// tombol refresh) tidak perlu memicu ulang seluruh logic wallet
/// (baca secure storage, dsb), dan sebaliknya.
///
/// `autoDispose` dipakai karena saldo cuma relevan SELAMA WalletScreen
/// dibuka — begitu user pindah tab, provider ini "dibuang" dan akan
/// fetch ulang (bukan nilai basi) saat dibuka lagi.
final walletBalanceProvider = FutureProvider.autoDispose<double>((ref) async {
  final wallet = await ref.watch(walletProvider.future);
  if (wallet == null) {
    throw StateError('Tidak ada wallet aktif untuk dicek saldonya.');
  }
  final result = await ref.read(walletRepositoryProvider).getBalance(wallet.address);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (balance) => balance,
  );
});
