import 'package:web3dart/web3dart.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/contract_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../services/wallet_service.dart';
import '../../../../services/web3_service.dart';
import '../../domain/repositories/donation_repository.dart';

/// Implementasi nyata donasi: baca mnemonic wallet aktif -> derive
/// credentials -> load contract -> kirim transaksi `donate(campaignId)`
/// dengan `value` sebesar nominal MATIC yang dipilih user.
///
/// SATU TRANSAKSI INI ADALAH INTI dari requirement checkpoint UTS-mu:
/// "satu alur utama harus berjalan dari input pengguna (donasi) sampai
/// data transaksi tercatat di jaringan blockchain."
class DonationRepositoryImpl implements DonationRepository {
  DonationRepositoryImpl(this._walletService, {Web3Service? web3Service})
      : _web3 = web3Service ?? Web3Service();

  final WalletService _walletService;
  final Web3Service _web3;

  @override
  Future<Either<Failure, String>> donate({
    required int campaignId,
    required double amountInMatic,
  }) async {
    try {
      final mnemonic = await _walletService.readMnemonic();
      if (mnemonic == null || mnemonic.isEmpty) {
        return const Left(WalletFailure(
          'Wallet belum dibuat. Buat atau import wallet terlebih dahulu sebelum berdonasi.',
        ));
      }

      final credentials = _walletService.credentialsFromMnemonic(mnemonic);

      // `loadContract()` melempar StateError kalau RPC/contract/ABI masih
      // placeholder — ditangkap di bawah sebagai ConfigurationFailure,
      // BUKAN TransactionFailure, supaya pesannya jelas ini masalah setup.
      final contract = await _web3.loadContract();
      final donateFunction = contract.function('donate');

      final weiAmount = _maticToWei(amountInMatic);

      final txHash = await _web3.client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: donateFunction,
          parameters: [BigInt.from(campaignId)],
          value: EtherAmount.fromBigInt(EtherUnit.wei, weiAmount),
        ),
        chainId: ContractConstants.chainId,
      );

      return Right(txHash);
    } on StateError catch (e) {
      return Left(ConfigurationFailure(e.message));
    } catch (e) {
      // Contoh penyebab di sini: saldo tidak cukup untuk gas fee,
      // campaignId tidak ditemukan di contract (require() gagal di
      // Solidity), atau koneksi RPC terputus di tengah pengiriman.
      return Left(TransactionFailure('Donasi gagal diproses: $e'));
    }
  }

  /// Konversi MATIC (double, mis. 0.01) ke wei (BigInt, integer utuh)
  /// LEWAT STRING — bukan `matic * 1e18` langsung.
  ///
  /// KENAPA? Floating point (`double`) tidak bisa merepresentasikan
  /// banyak angka desimal secara eksak (mis. 0.1 di biner sebenarnya
  /// 0.1000000000000000055...). Untuk NOMINAL UANG yang dikirim
  /// sungguhan ke blockchain, kesalahan pembulatan sekecil apa pun tidak
  /// boleh terjadi. Lewat string, kita kontrol penuh setiap digit.
  BigInt _maticToWei(double matic) {
    final fixed = matic.toStringAsFixed(18); // contoh: "0.010000000000000000"
    final parts = fixed.split('.');
    final wholePart = BigInt.parse(parts[0]);
    final fracString = parts[1].padRight(18, '0').substring(0, 18);
    final fracPart = BigInt.parse(fracString);
    return wholePart * BigInt.from(10).pow(18) + fracPart;
  }
}
