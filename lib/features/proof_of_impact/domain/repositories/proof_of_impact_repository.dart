import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/proof_of_impact.dart';

abstract class ProofOfImpactRepository {
  Future<Either<Failure, String>> uploadProof({
    required String photoPath,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  });

  Future<Either<Failure, ProofOfImpact?>> getLastProof();
}
