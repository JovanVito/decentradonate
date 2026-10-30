import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/ripple_ring.dart';
import '../../domain/entities/campaign.dart';

/// Kartu kampanye gaya "Riak": cincin riak sebagai progres,
/// judul serif, dan stempel bukti dampak.
class CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;

  const CampaignCard({super.key, required this.campaign, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (campaign.imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image(
                          image: campaign.imageUrl!.startsWith('http')
                              ? NetworkImage(campaign.imageUrl!) as ImageProvider
                              : AssetImage(campaign.imageUrl!),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _ImageFallback(),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ] else ...[
                      const _ImageFallback(),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded,
                                  size: 15, color: AppColors.verifiedText),
                              const SizedBox(width: 4),
                              const Text('TRANSPARAN',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.verifiedText,
                                      letterSpacing: .5)),
                              const Spacer(),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: AppColors.textSecondary),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            campaign.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.fraunces(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_fmt(campaign.collectedAmount)} MATIC terkumpul',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                    Text('${(campaign.progressPercent * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.verifiedText)),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: campaign.progressPercent,
                    minHeight: 8,
                    backgroundColor: AppColors.paperDeep,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.ripple),
                  ),
                ),
                const SizedBox(height: 7),
                Text('Target ${_fmt(campaign.targetAmount)} MATIC · ${campaign.organizer}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _fmt(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
            color: AppColors.paperDeep,
            borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.volunteer_activism_rounded,
            color: AppColors.ripple, size: 28),
      );
}
