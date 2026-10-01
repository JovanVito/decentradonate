import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/campaign_list_provider.dart';
import '../widgets/campaign_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(campaignListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle,
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: campaigns.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => ErrorStateWidget(
          title: AppStrings.errorCampaignTitle,
          subtitle: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.read(campaignListProvider.notifier).retry(),
        ),
        data: (data) {
          if (data.isEmpty) {
            return const EmptyStateWidget(
              title: AppStrings.emptyCampaignTitle,
              subtitle: AppStrings.emptyCampaignSubtitle,
              icon: Icons.volunteer_activism_outlined,
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(campaignListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, i) {
                final campaign = data[i];
                return CampaignCard(
                  campaign: campaign,
                  onTap: () =>
                      context.push('/campaign/${campaign.id}', extra: campaign),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
