import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../services/wallet_service.dart';
import '../../../../services/web3_service.dart';
import '../../domain/entities/wallet_info.dart';
import '../../domain/repositories/wallet_repository.dart';

/// Implementasi nyata `WalletRepository`. Ini satu-satunya file yang tahu
/// bahwa di baliknya ada `WalletService` (bip39 + secure storage) DAN
/// `Web3Service` (koneksi blockchain) sekaligus.
///
/// POLA YANG DIULANG DI SETIAP METHOD: try-catch di sini, BUKAN di
/// presentation. Kenapa? Supaya UI tidak pernah perlu tahu tipe exception
/// asli (mis. `PlatformException` dari secure storage, atau `StateError`
/// dari Web3Service) — UI cukup terima `Failure` yang sudah punya pesan
/// ramah-pengguna dalam Bahasa Indonesia.
class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._service, {Web3Service? web3Service})
      : _web3 = web3Service ?? Web3Service();

  final WalletService _service;
  final Web3Service _web3;

  @override
  Future<Either<Failure, WalletInfo?>> getActiveWallet() async {
    try {
      final mnemonic = await _service.readMnemonic();
      if (mnemonic == null || mnemonic.isEmpty) {
        return const Right(null); // Right(null) = "sukses, tapi belum ada wallet"
      }
      final credentials = _service.credentialsFromMnemonic(mnemonic);
      return Right(WalletInfo(address: credentials.address.hexEip55));
    } catch (e) {
      return Left(CacheFailure('Gagal membaca data wallet: $e'));
    }
  }

  @override
  Future<Either<Failure, WalletInfo>> createWallet() async {
    try {
      final mnemonic = _service.generateMnemonic();
      final credentials = _service.credentialsFromMnemonic(mnemonic);
      await _service.saveMnemonic(mnemonic);
      return Right(WalletInfo(
        address: credentials.address.hexEip55,
        mnemonicForBackup: mnemonic,
      ));
    } catch (e) {
      return Left(WalletFailure('Gagal membuat wallet baru: $e'));
    }
  }

  @override
  Future<Either<Failure, WalletInfo>> importWallet(String mnemonic) async {
    final trimmed = mnemonic.trim();

    if (!_service.isValidMnemonic(trimmed)) {
      return const Left(WalletFailure(
        'Frasa mnemonic tidak valid. Periksa kembali 12 kata dan urutannya (pisahkan dengan spasi).',
      ));
    }

    try {
      final credentials = _service.credentialsFromMnemonic(trimmed);
      await _service.saveMnemonic(trimmed);
      return Right(WalletInfo(address: credentials.address.hexEip55));
    } catch (e) {
      return Left(WalletFailure('Gagal mengimpor wallet: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteWallet() async {
    try {
      await _service.deleteWallet();
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Gagal menghapus wallet: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getBalance(String address) async {
    try {
      final amount = await _web3.getBalance(address);
      // `getInWei` (BigInt) adalah getter paling stabil di web3dart across
      // versi. Konversi manual ke MATIC (1 MATIC = 1e18 wei) dengan
      // `toDouble()` cukup presisi untuk kebutuhan TAMPILAN (dibulatkan ke
      // beberapa desimal di UI) — untuk akuntansi transaksi yang butuh
      // presisi penuh, tetap pakai nilai wei (BigInt) asli, jangan double ini.
      final wei = amount.getInWei;
      final matic = wei.toDouble() / 1e18;
      return Right(matic);
    } on StateError catch (e) {
      // StateError dilempar Web3Service saat RPC/contract belum
      // dikonfigurasi — ini masalah SETUP, bukan masalah jaringan.
      return Left(ConfigurationFailure(e.message));
    } catch (e) {
      return Left(RpcFailure('Gagal mengambil saldo: $e'));
    }
  }
}
