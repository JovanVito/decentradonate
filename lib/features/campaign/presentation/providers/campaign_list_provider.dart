import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/campaign_repository_impl.dart';
import '../../domain/entities/campaign.dart';
import '../../domain/repositories/campaign_repository.dart';

final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  return const CampaignRepositoryImpl();
});

class CampaignListNotifier extends AsyncNotifier<List<Campaign>> {
  @override
  Future<List<Campaign>> build() async {
    final result = await ref.watch(campaignRepositoryProvider).getCampaigns();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (data) => data,
    );
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    ref.invalidateSelf();
  }
}

final campaignListProvider =
    AsyncNotifierProvider<CampaignListNotifier, List<Campaign>>(
  CampaignListNotifier.new,
);
