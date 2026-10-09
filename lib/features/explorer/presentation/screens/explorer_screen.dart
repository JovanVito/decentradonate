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
    final explorerAsync = ref.watch(explorerProvider);
    return Scaffold(
      appBar: AppBar(
          title: const Text('Riwayat Transaksi',
              style: TextStyle(fontWeight: FontWeight.bold))),
      body: explorerAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, st) => ErrorStateWidget(
          title: 'Gagal Memuat History Donasi',
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
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kampanye #${tx.campaignId}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            '${tx.timestamp.hour}:${tx.timestamp.minute.toString().padLeft(2, '0')} · tx ${tx.txHash.substring(0, 6)}…',
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '−${tx.amount.toStringAsFixed(4)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
