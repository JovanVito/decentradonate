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
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RippleRing(percent: campaign.progressPercent, size: 54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fraunces(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Terkumpul ${_fmt(campaign.collectedAmount)} / ${_fmt(campaign.targetAmount)} MATIC',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 12, color: AppColors.verifiedText),
                          const SizedBox(width: 4),
                          Text(
                            '${(campaign.progressPercent * 100).toStringAsFixed(0)}% tercapai',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.verifiedText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (campaign.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image(
                      image: campaign.imageUrl!.startsWith('http')
                          ? NetworkImage(campaign.imageUrl!) as ImageProvider
                          : AssetImage(campaign.imageUrl!),
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 58,
                        height: 58,
                        color: AppColors.paperDeep,
                        child: const Icon(Icons.volunteer_activism_rounded,
                            color: AppColors.ripple),
                      ),
                    ),
                  ),
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
