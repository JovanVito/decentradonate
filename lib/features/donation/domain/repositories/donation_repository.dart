import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

/// Kontrak untuk aksi donasi. Domain TIDAK tahu apa-apa soal web3dart,
/// EthPrivateKey, atau signing transaksi — cukup tahu "kirim sekian MATIC
/// ke campaign tertentu, balas dengan hash transaksi atau Failure".
abstract class DonationRepository {
  /// Return: hash transaksi (String, format "0x...") kalau sukses.
  Future<Either<Failure, String>> donate({
    required int campaignId,
    required double amountInMatic,
  });
}
