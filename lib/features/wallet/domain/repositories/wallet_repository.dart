import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_info.dart';

/// Kontrak (interface) — domain TIDAK tahu implementasinya pakai
/// flutter_secure_storage atau bip39 sama sekali. Kalau nanti ganti
/// mekanisme storage, file ini TIDAK PERNAH perlu diubah.
abstract class WalletRepository {
  /// Null di posisi Right berarti "belum ada wallet" — ini beda dengan
  /// Left(Failure) yang berarti "gagal membaca". Presentation layer harus
  /// membedakan dua kasus ini (Empty state vs Error state).
  Future<Either<Failure, WalletInfo?>> getActiveWallet();

  Future<Either<Failure, WalletInfo>> createWallet();

  Future<Either<Failure, WalletInfo>> importWallet(String mnemonic);

  Future<Either<Failure, Unit>> deleteWallet();

  /// Saldo dalam MATIC (bukan wei) — konversi sudah dilakukan di
  /// implementasi, supaya presentation layer terima angka siap-pakai.
  Future<Either<Failure, double>> getBalance(String address);
}
