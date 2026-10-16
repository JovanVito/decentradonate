import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_config.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/campaign.dart';
import '../../domain/repositories/campaign_repository.dart';

/// Repository vertical slice campaign: Home -> provider -> repository -> Supabase.
/// `fallbackToDummy` hanya untuk demo lokal saat Supabase belum dikonfigurasi.
class CampaignRepositoryImpl implements CampaignRepository {
  final SupabaseClient? client;
  final bool fallbackToDummy;
  final bool shouldFail;
  final bool returnEmpty;
  final Duration delay;
  final Future<List<Map<String, dynamic>>> Function()? fetchRows;

  const CampaignRepositoryImpl({
    this.client,
    this.fallbackToDummy = true,
    this.shouldFail = false,
    this.returnEmpty = false,
    this.delay = Duration.zero,
    this.fetchRows,
  });

  SupabaseClient? get _supabase => client ?? supabaseClient;

  @override
  Future<Either<Failure, List<Campaign>>> getCampaigns() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldFail) {
      return const Left(NetworkFailure('Gagal memuat kampanye. Coba lagi.'));
    }
    if (returnEmpty) return const Right(<Campaign>[]);

    final api = _supabase;
    if (fetchRows == null && (api == null || !SupabaseConfig.isConfigured)) {
      if (fallbackToDummy) return Right(dummyCampaigns());
      return const Left(ConfigurationFailure('Supabase belum dikonfigurasi.'));
    }

    try {
      final data = fetchRows != null
          ? await fetchRows!()
          : (await api!.from('campaigns').select().order('created_at')) as List;
      final campaigns = data
          .map(
              (row) => Campaign.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
      return Right(campaigns);
    } on CampaignModelException catch (error) {
      return Left(CampaignApiFailure('JSON campaign rusak: ${error.message}'));
    } on PostgrestException catch (error) {
      return Left(NetworkFailure('Gagal memuat campaign: ${error.message}'));
    } on FormatException catch (error) {
      return Left(CampaignApiFailure('Format JSON campaign rusak: $error'));
    } catch (error) {
      return Left(NetworkFailure('Koneksi campaign gagal: $error'));
    }
  }
}
