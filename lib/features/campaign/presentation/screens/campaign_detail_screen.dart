import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../donation/presentation/widgets/donate_bottom_sheet.dart';
import '../../domain/entities/campaign.dart';

/// Halaman Detail Kampanye.
/// Menerima `Campaign` langsung lewat `extra` dari go_router (lihat
/// app_router.dart) — jadi tidak perlu fetch ulang data saat berpindah
/// dari Home ke Detail. Kalau nanti user deep-link langsung ke halaman
/// ini (mis. dari notifikasi) tanpa `extra`, kita fallback fetch by ID
/// di Stage 2 lewat repository.
///
/// `ConsumerWidget` dipakai mulai Langkah 2.3 supaya bisa membuka
/// `DonateBottomSheet` yang butuh akses provider donasi.
class CampaignDetailScreen extends ConsumerWidget {
  final Campaign? campaign;
  final String campaignId;

  const CampaignDetailScreen({super.key, required this.campaignId, this.campaign});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = campaign;

    if (c == null) {
      // Placeholder Stage 1: harusnya di Stage 2 ini memicu fetch by ID.
      return Scaffold(
        appBar: AppBar(title: Text('Kampanye #$campaignId')),
        body: const Center(child: Text('Detail tidak ditemukan (belum fetch by ID).')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kampanye')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.volunteer_activism_rounded,
                  size: 56, color: AppColors.primary.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            Text(c.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('Organizer: ${c.organizer}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: c.progressPercent,
                minHeight: 8,
                backgroundColor: AppColors.background,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text('${c.collectedAmount} ETH terkumpul dari target ${c.targetAmount} ETH',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            const Text('Deskripsi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(c.description, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Donasi Sekarang',
              icon: Icons.favorite_rounded,
              onPressed: () {
                // `c.id` (String, data dummy Stage 1) di-parse ke int
                // karena contract Solidity memakai `uint256 campaignId`.
                // Lihat catatan scope di DonateBottomSheet: id ini harus
                // cocok dengan campaign yang BENAR-BENAR ada di contract.
                final parsedId = int.tryParse(c.id) ?? 0;
                DonateBottomSheet.show(
                  context,
                  campaignId: parsedId,
                  campaignTitle: c.title,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
