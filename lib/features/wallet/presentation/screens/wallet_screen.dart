import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/wallet_info.dart';
import '../providers/wallet_providers.dart';

/// Halaman Wallet — SEKARANG SUDAH NYATA, bukan dummy Stage 1 lagi.
///
/// `ConsumerWidget` (bukan `StatelessWidget`) supaya bisa `ref.watch`
/// provider. `walletAsync.when(...)` adalah cara Riverpod memaksa kita
/// menangani ketiga state (loading/error/data) — konsepnya SAMA PERSIS
/// dengan `switch` di ViewState Stage 1, cuma sudah dibungkus rapi oleh
/// framework, jadi kita tidak perlu bikin ViewState manual lagi untuk data
/// yang datang dari provider.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.walletTitle, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: walletAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, st) => ErrorStateWidget(
          title: 'Gagal Memuat Wallet',
          subtitle: err.toString(),
          onRetry: () => ref.invalidate(walletProvider),
        ),
        data: (wallet) {
          if (wallet == null) return _NoWalletView(ref: ref);
          return _HasWalletView(wallet: wallet);
        },
      ),
    );
  }
}

class _NoWalletView extends StatelessWidget {
  final WidgetRef ref;
  const _NoWalletView({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Expanded(
            child: EmptyStateWidget(
              title: 'Belum Ada Dompet',
              subtitle: AppStrings.walletEmptySubtitle,
              icon: Icons.account_balance_wallet_outlined,
            ),
          ),
          PrimaryButton(
            label: AppStrings.createWallet,
            icon: Icons.add_circle_outline,
            onPressed: () async {
              final mnemonic = await ref.read(walletProvider.notifier).createWallet();
              if (mnemonic != null && context.mounted) {
                context.push('/wallet/backup', extra: mnemonic);
              }
              // Kalau mnemonic null, walletProvider sudah dalam AsyncError
              // state dan ErrorStateWidget di atas otomatis tampil —
              // tidak perlu penanganan tambahan di sini.
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/wallet/import'),
            icon: const Icon(Icons.download_outlined, color: AppColors.primary),
            label: const Text(AppStrings.importWallet, style: TextStyle(color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HasWalletView extends ConsumerWidget {
  final WalletInfo wallet;
  const _HasWalletView({required this.wallet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alamat Wallet', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          wallet.address,
                          style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.primary),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: wallet.address));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Alamat disalin')),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      InkWell(
                        onTap: () => ref.invalidate(walletBalanceProvider),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(Icons.refresh_rounded, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('Refresh', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  balanceAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                    data: (balance) => Text(
                      '${balance.toStringAsFixed(4)} MATIC',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    error: (err, st) => _BalanceErrorNote(message: err.toString()),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, ref),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text('Hapus Wallet dari Perangkat Ini', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Wallet?'),
        content: const Text(
          'Pastikan kamu sudah mencatat seed phrase di tempat aman. '
          'Tanpa seed phrase, wallet ini TIDAK BISA dipulihkan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(walletProvider.notifier).deleteWallet();
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

/// Pesan error saldo yang MEMBEDAKAN dua kasus:
/// 1. Konfigurasi belum diisi (RPC/contract/ABI masih placeholder) —
///    ini salah SETUP, arahkan ke dokumentasi.
/// 2. Kegagalan jaringan sungguhan setelah konfigurasi lengkap.
/// Perhatikan: kita hanya cek isi pesan (string) di sini karena
/// `AsyncValue.error` cuma menyimpan `Object? error`, bukan `Failure` asli
/// (informasi tipe hilang saat lewat `Exception(failure.message)` di
/// wallet_providers.dart). Trade-off yang sadar dipilih demi kesederhanaan
/// di Stage 2 — kalau mau lebih rapi, `walletBalanceProvider` bisa
/// diubah mengembalikan `Either<Failure, double>` langsung tanpa `throw`.
class _BalanceErrorNote extends StatelessWidget {
  final String message;
  const _BalanceErrorNote({required this.message});

  @override
  Widget build(BuildContext context) {
    final isConfigIssue = message.contains('belum dikonfigurasi') || message.contains('placeholder');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isConfigIssue ? 'Konfigurasi Blockchain Belum Lengkap' : 'Gagal Memuat Saldo',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error),
        ),
        const SizedBox(height: 2),
        Text(
          isConfigIssue
              ? 'Lengkapi RPC URL & contract address di contract_constants.dart (lihat blockchain/DEPLOY_GUIDE.md).'
              : message,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
