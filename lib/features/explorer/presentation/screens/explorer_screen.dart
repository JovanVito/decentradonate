import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${tx.campaignId}')),
                  title: Text('Campaign #${tx.campaignId}'),
                  subtitle: Text('${tx.amount.toStringAsFixed(4)} MATIC'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          '${tx.timestamp.hour}:${tx.timestamp.minute.toString().padLeft(2, '0')}'),
                      Text('${tx.txHash.substring(0, 6)}...',
                          style: const TextStyle(
                              fontSize: 10, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
