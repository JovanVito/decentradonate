import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/campaign_management_repository_impl.dart';
import '../../domain/repositories/campaign_management_repository.dart';

final campaignManagementRepositoryProvider =
    Provider<CampaignManagementRepository>((ref) {
  return const CampaignManagementRepositoryImpl();
});
