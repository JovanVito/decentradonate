import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/campaign.dart';

/// Kartu kampanye reusable — dipakai di list Home.
/// Dumb widget: hanya menerima data + callback, tidak tahu soal state
/// management/provider sama sekali (mudah di-preview & di-test).
class CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;

  const CampaignCard({super.key, required this.campaign, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.volunteer_activism_rounded,
                    size: 40, color: AppColors.primary.withOpacity(0.6)),
              ),
              const SizedBox(height: 12),
              Text(
                campaign.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: campaign.progressPercent,
                  minHeight: 6,
                  backgroundColor: AppColors.background,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${campaign.collectedAmount} / ${campaign.targetAmount} MATIC',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('${(campaign.progressPercent * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
