import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_config.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/campaign.dart';
import '../../domain/repositories/campaign_management_repository.dart';

class CampaignManagementRepositoryImpl implements CampaignManagementRepository {
  final SupabaseClient? client;

  const CampaignManagementRepositoryImpl({this.client});

  @override
  Future<Either<Failure, Campaign>> createCampaign({
    required String title,
    required String description,
    required double targetAmount,
  }) async {
    final api = client ?? supabaseClient;
    final user = api?.auth.currentUser;
    if (api == null || !SupabaseConfig.isConfigured) {
      return const Left(ConfigurationFailure('Supabase belum dikonfigurasi.'));
    }
    if (user == null) {
      return const Left(UnexpectedFailure('Sesi organizer belum tersedia.'));
    }
    try {
      final row = await api
          .from('campaigns')
          .insert({
            'organizer_id': user.id,
            'title': title.trim(),
            'description': description.trim(),
            'target_amount': targetAmount,
            'collected_amount': 0,
          })
          .select()
          .single();
      return Right(Campaign.fromJson(Map<String, dynamic>.from(row)));
    } on CampaignModelException catch (error) {
      return Left(CampaignApiFailure(error.message));
    } on PostgrestException catch (error) {
      return Left(NetworkFailure('Gagal menyimpan campaign: ${error.message}'));
    } catch (error) {
      return Left(NetworkFailure('Koneksi campaign gagal: $error'));
    }
  }
}
