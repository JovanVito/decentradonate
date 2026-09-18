import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/view_state.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/campaign.dart';
import '../widgets/campaign_card.dart';

/// Halaman Home / daftar kampanye.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ViewState<List<Campaign>> _debugState = ViewLoaded(dummyCampaigns());

  void _setState(ViewState<List<Campaign>> s) => setState(() => _debugState = s);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle,
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final state = _debugState;
    return switch (state) {
      ViewInitial() || ViewLoading() => const LoadingWidget(),
      ViewEmpty() => const EmptyStateWidget(
          title: AppStrings.emptyCampaignTitle,
          subtitle: AppStrings.emptyCampaignSubtitle,
          icon: Icons.volunteer_activism_outlined,
        ),
      ViewError(:final message) => ErrorStateWidget(
          title: AppStrings.errorCampaignTitle,
          subtitle: message,
          onRetry: () => _setState(ViewLoaded(dummyCampaigns())),
        ),
      ViewLoaded(:final data) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, i) {
              final campaign = data[i];
              return CampaignCard(
                campaign: campaign,
                onTap: () => context.push('/campaign/${campaign.id}', extra: campaign),
              );
            },
          ),
        ),
    };
  }
}
