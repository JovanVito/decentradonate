import 'package:web3dart/web3dart.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/transaction_history.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../../../services/web3_service.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final Web3Service _web3;

  TransactionRepositoryImpl(this._web3);

  @override
  Future<Either<Failure, List<TransactionHistory>>> getTransactionHistory() async {
    try {
      final contract = await _web3.loadContract();
      final event = contract.event('DonationReceived');
      final options = FilterOptions.events(
        contract: contract,
        event: event,
        fromBlock: BlockNum.genesis(),
      );
      final stream = _web3.client.events(options);

      final transactions = <TransactionHistory>[];
      await for (final log in stream.take(200)) {
        try {
          final decoded = event.decodeResults(log.topics ?? [], log.data ?? '');
          if (decoded.length >= 3) {
            final campaignId = decoded[0] as BigInt;
            final donor = decoded[1] as EthereumAddress;
            final amount = decoded[2] as BigInt;
            transactions.add(TransactionHistory(
              campaignId: campaignId.toInt(),
              donor: donor.hexEip55,
              amount: (amount / BigInt.from(10).pow(18)).toDouble(),
              timestamp: DateTime.now(),
              txHash: log.transactionHash ?? 'unknown',
            ));
          }
        } catch (_) {
          // Skip logs that don't match the event signature
        }
      }

      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Right(transactions);
    } on StateError catch (e) {
      return Left(ConfigurationFailure(e.message));
    } catch (e) {
      return Left(TransactionFailure('Gagal memuat riwayat transaksi: $e'));
    }
  }
}
