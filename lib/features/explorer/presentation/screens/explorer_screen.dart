import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/explorer_provider.dart';

class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(explorerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final explorerAsync = ref.watch(explorerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer & Saldo', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Wallet Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo Wallet', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    balanceAsync.when(
                      loading: () => const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
                      data: (balance) => Text(
                        '${balance.toStringAsFixed(4)} ETH',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      error: (err, st) => Text(
                        'Node tidak aktif. Jalankan:\nnpx hardhat node',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                    ),
                    const Divider(height: 24),
                    const Text('Alamat', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      'Ketik wallet untuk melihat saldo',
                      style: TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Transaction History
            const Text('Riwayat Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            explorerAsync.when(
              loading: () => const LoadingWidget(),
              error: (err, st) => ErrorStateWidget(
                title: 'Gagal Memuat Riwayat',
                subtitle: err.toString(),
                onRetry: () => ref.read(explorerProvider.notifier).refresh(),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'Belum Ada Transaksi',
                    subtitle: 'Donasi pertama Anda akan muncul di sini.',
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${tx.campaignId}'),
                        ),
                        title: Text('Campaign #${tx.campaignId}'),
                        subtitle: Text('${tx.amount.toStringAsFixed(4)} ETH'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${tx.timestamp.hour}:${tx.timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(
                              '${tx.txHash.substring(0, 6)}...',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
