import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/ripple_ring.dart';
import '../../../donation/presentation/widgets/donate_bottom_sheet.dart';
import '../../domain/entities/campaign.dart';

/// Halaman Detail Kampanye — gaya "Riak": cincin besar, chip nominal,
/// dan jejak dampak bergaya buku kas.
class CampaignDetailScreen extends ConsumerWidget {
  final Campaign? campaign;
  final String campaignId;

  const CampaignDetailScreen(
      {super.key, required this.campaignId, this.campaign});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = campaign;

    if (c == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Kampanye #$campaignId')),
        body: const Center(
            child: Text('Detail tidak ditemukan (belum fetch by ID).')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kampanye')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RippleRing(
                  percent: c.progressPercent,
                  size: 120,
                  inner: AppColors.paper,
                  labelStyle: GoogleFonts.fraunces(
                      fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Terkumpul',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Text(
                        '${_fmt(c.collectedAmount)} MATIC',
                        style: GoogleFonts.fraunces(
                            fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      Text('dari ${_fmt(c.targetAmount)} MATIC',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(c.title,
                style: GoogleFonts.fraunces(
                    fontSize: 17, fontWeight: FontWeight.w600, height: 1.15)),
            const SizedBox(height: 6),
            Text('Organizer: ${c.organizer}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            if (c.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: Image(
                    image: c.imageUrl!.startsWith('http')
                        ? NetworkImage(c.imageUrl!) as ImageProvider
                        : AssetImage(c.imageUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.paperDeep,
                      alignment: Alignment.center,
                      child: const Icon(Icons.volunteer_activism_rounded,
                          size: 48, color: AppColors.ripple),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            const _SectionLabel('Deskripsi'),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(c.description,
                  style: const TextStyle(fontSize: 13.5, height: 1.5)),
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Jejak Dampak'),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.only(left: 14),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.border, width: 2),
                ),
              ),
              child: Column(
                children: [
                  _ImpactStep(
                    title: 'Donasi tercatat on-chain',
                    detail: 'Setiap donasi tersimpan permanen di blockchain.',
                    code: 'contract: donate()',
                  ),
                  _ImpactStep(
                    title: 'Bukti dampak diunggah',
                    detail: 'Foto + GPS disimpan ke IPFS sebagai bukti.',
                    code: 'ipfs://…',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Donasi lewat Wallet',
              icon: Icons.favorite_rounded,
              onPressed: () {
                final parsedId = int.tryParse(c.id) ?? 0;
                DonateBottomSheet.show(
                  context,
                  campaignId: parsedId,
                  campaignTitle: c.title,
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static String _fmt(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.textSecondary,
        ),
      );
}

class _ImpactStep extends StatelessWidget {
  final String title;
  final String detail;
  final String code;

  const _ImpactStep({
    required this.title,
    required this.detail,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle,
                  size: 14, color: AppColors.verifiedText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(detail,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F7EC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(code,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.verifiedText,
                    fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}
