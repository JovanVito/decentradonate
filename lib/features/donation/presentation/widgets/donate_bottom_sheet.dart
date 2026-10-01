import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/donation_providers.dart';

/// Aturan validasi nominal donasi, dipisah sebagai fungsi murni supaya
/// gampang diuji tanpa harus memompa widget.
String? validateDonationAmount(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Nominal wajib diisi';
  }
  final normalized = value.trim().replaceAll(',', '.');
  final amount = double.tryParse(normalized);
  if (amount == null) return 'Masukkan angka yang valid';
  if (amount <= 0) return 'Nominal harus lebih dari 0';
  if (amount < 0.001) return 'Minimal donasi 0,001';
  if (amount > 1000000) return 'Nominal terlalu besar';
  return null;
}

/// Bottom sheet input nominal donasi + eksekusi transaksi.
///
/// CATATAN SCOPE: `campaignId` HARUS cocok dengan ID campaign yang
/// BENAR-BENAR ada di smart contract (dibuat lewat `createCampaign`).
/// Home screen memakai data dummy tahap awal — sinkronisasi daftar
/// campaign asli dari on-chain adalah pekerjaan lanjutan.
class DonateBottomSheet extends ConsumerStatefulWidget {
  final int campaignId;
  final String campaignTitle;

  const DonateBottomSheet({
    super.key,
    required this.campaignId,
    required this.campaignTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required int campaignId,
    required String campaignTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DonateBottomSheet(campaignId: campaignId, campaignTitle: campaignTitle),
    );
  }

  @override
  ConsumerState<DonateBottomSheet> createState() => _DonateBottomSheetState();
}

class _DonateBottomSheetState extends ConsumerState<DonateBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController(text: '0.01');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount =
        double.parse(_controller.text.trim().replaceAll(',', '.'));
    ref.read(donationProvider.notifier).donate(
          campaignId: widget.campaignId,
          amountInMatic: amount,
        );
  }

  @override
  Widget build(BuildContext context) {
    final donationState = ref.watch(donationProvider);

    ref.listen<AsyncValue<String?>>(donationProvider, (previous, next) {
      final txHash = next.valueOrNull;
      if (txHash != null) {
        Navigator.of(context).pop();
        _showSuccessDialog(context, txHash);
        ref.read(donationProvider.notifier).reset();
      }
    });

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Donasi untuk',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text(widget.campaignTitle,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: validateDonationAmount,
              decoration: const InputDecoration(
                labelText: 'Nominal',
                border: OutlineInputBorder(),
                suffixText: 'MATIC',
              ),
            ),
            if (donationState.hasError) ...[
              const SizedBox(height: 10),
              Text(
                donationState.error.toString().replaceFirst('Exception: ', ''),
                style:
                    const TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Kirim Donasi',
              icon: Icons.favorite_rounded,
              isLoading: donationState.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String txHash) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Donasi Terkirim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transaksi berhasil dikirim ke jaringan.'),
            const SizedBox(height: 10),
            const Text('Hash Transaksi:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText(txHash,
                      style: const TextStyle(
                          fontSize: 11, fontFamily: 'monospace')),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded,
                      size: 18, color: AppColors.primary),
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: txHash)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup')),
        ],
      ),
    );
  }
}
