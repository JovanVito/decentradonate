import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web3dart/web3dart.dart';
import '../../domain/entities/transaction_history.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../../../core/providers/service_providers.dart';

class ExplorerNotifier extends AsyncNotifier<List<TransactionHistory>> {
  @override
  Future<List<TransactionHistory>> build() async {
    final result = await ref.read(transactionRepositoryProvider).getTransactionHistory();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (txs) => txs,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await ref.read(transactionRepositoryProvider).getTransactionHistory();
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (txs) => AsyncData(txs),
    );
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.read(web3ServiceProvider));
});

final explorerProvider = AsyncNotifierProvider<ExplorerNotifier, List<TransactionHistory>>(
  ExplorerNotifier.new,
);

final walletBalanceProvider = FutureProvider.autoDispose<double>((ref) async {
  final walletService = ref.read(walletServiceProvider);
  final mnemonic = await walletService.readMnemonic();
  if (mnemonic == null || mnemonic.isEmpty) {
    throw StateError('Tidak ada wallet aktif.');
  }
  final credentials = walletService.credentialsFromMnemonic(mnemonic);
  final etherAmount = await ref.read(web3ServiceProvider).getBalance(credentials.address.hexEip55);
  return etherAmount.getValueInUnit(EtherUnit.ether);
});
