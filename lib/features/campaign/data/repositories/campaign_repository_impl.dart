import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/campaign.dart';
import '../../domain/repositories/campaign_repository.dart';

class CampaignRepositoryImpl implements CampaignRepository {
  final Duration delay;
  final bool shouldFail;
  final bool returnEmpty;

  const CampaignRepositoryImpl({
    this.delay = const Duration(milliseconds: 400),
    this.shouldFail = false,
    this.returnEmpty = false,
  });

  @override
  Future<Either<Failure, List<Campaign>>> getCampaigns() async {
    await Future.delayed(delay);
    if (shouldFail) {
      return const Left(
        NetworkFailure('Gagal memuat kampanye. Periksa koneksi lalu coba lagi.'),
      );
    }
    if (returnEmpty) return const Right(<Campaign>[]);
    return Right(dummyCampaigns());
  }
}
