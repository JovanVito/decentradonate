import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/transaction_history.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<TransactionHistory>>> getTransactionHistory();
}
