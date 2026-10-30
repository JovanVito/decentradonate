import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/campaign.dart';

abstract class CampaignManagementRepository {
  Future<Either<Failure, Campaign>> createCampaign({
    required String title,
    required String description,
    required double targetAmount,
  });
}
