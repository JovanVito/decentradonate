import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/donation_providers.dart';

/// Bottom sheet input nominal donasi + eksekusi transaksi.
///
/// CATATAN SCOPE PENTING: `campaignId` di sini HARUS cocok dengan ID
/// campaign yang BENAR-BENAR ada di smart contract (dibuat lewat
/// `createCampaign` — lihat blockchain/DEPLOY_GUIDE.md Langkah 7).
/// Home screen saat ini MASIH menampilkan data dummy dari Stage 1 —
/// sinkronisasi daftar campaign asli dari on-chain adalah pekerjaan
/// lanjutan di luar Langkah 2.3 ini (jangan bingung kalau donasi ke
/// campaignId dari data dummy gagal karena campaign itu belum ada
/// di contract yang sungguhan).
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
      isScrollControlled: true, // wajib true supaya keyboard-safe (lihat padding di build())
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
  final _controller = TextEditingController(text: '0.01');
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_controller.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Masukkan nominal MATIC yang valid (lebih dari 0).');
      return;
    }
    setState(() => _errorText = null);
    ref.read(donationProvider.notifier).donate(
          campaignId: widget.campaignId,
          amountInMatic: amount,
        );
  }

  @override
  Widget build(BuildContext context) {
    final donationState = ref.watch(donationProvider);

    // `ref.listen` (bukan `ref.watch`) dipakai KHUSUS untuk efek samping
    // satu kali (tutup sheet + munculkan dialog sukses) — kalau dipakai
    // `ref.watch` biasa, dialog bisa muncul berkali-kali tiap widget
    // rebuild selama state masih AsyncData(txHash) yang sama.
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
        // Keyboard-safe: dorong konten ke atas keyboard, bukan tertutup.
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Donasi untuk', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(widget.campaignTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Nominal',
              border: const OutlineInputBorder(),
              errorText: _errorText,
              suffixText: 'MATIC',
            ),
          ),
          if (donationState.hasError) ...[
            const SizedBox(height: 10),
            Text(
              donationState.error.toString(),
              style: const TextStyle(fontSize: 12, color: AppColors.error),
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
    );
  }

  void _showSuccessDialog(BuildContext context, String txHash) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Donasi Terkirim 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transaksi berhasil dikirim ke jaringan Polygon Amoy.'),
            const SizedBox(height: 10),
            const Text('Hash Transaksi:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText(txHash, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                  onPressed: () => Clipboard.setData(ClipboardData(text: txHash)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Cek di PolygonScan Amoy: amoy.polygonscan.com/tx/<hash-ini>',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }
}
