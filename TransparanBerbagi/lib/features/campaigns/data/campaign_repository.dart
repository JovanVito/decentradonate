import 'package:decentradonate/features/campaigns/domain/campaign.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final campaignRepositoryProvider = Provider<CampaignRepository?>((ref) => null);

class CampaignRepository {
  const CampaignRepository(this.client);

  static const _fields =
      'id,title,organizer_name,category,story,target_amount,raised_amount,allocated_amount,donor_count';
  static const _publicStatuses = ['published', 'closed'];

  final SupabaseClient client;

  Future<List<Campaign>> list() async {
    final rows = await client
        .from('campaigns')
        .select(_fields)
        .inFilter('status', _publicStatuses)
        .order('created_at', ascending: false);
    return rows.map(Campaign.fromRow).toList(growable: false);
  }

  Future<Campaign?> detail(String id) async {
    final row = await client
        .from('campaigns')
        .select(_fields)
        .eq('id', id)
        .inFilter('status', _publicStatuses)
        .maybeSingle();
    return row == null ? null : Campaign.fromRow(row);
  }

  Future<List<PublishedAllocation>> allocations(String id) async {
    final rows = await client
        .from('fund_allocations')
        .select('description,category,amount,published_at')
        .eq('campaign_id', id)
        .eq('status', 'published')
        .order('published_at', ascending: false);
    return rows.map(PublishedAllocation.fromRow).toList(growable: false);
  }
}
