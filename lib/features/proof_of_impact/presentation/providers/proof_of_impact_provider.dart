import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/proof_of_impact_repository.dart';
import '../../data/repositories/proof_of_impact_repository_impl.dart';

class ProofOfImpactNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<void> uploadProof({
    required String photoPath,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(proofOfImpactRepositoryProvider)
        .uploadProof(
          photoPath: photoPath,
          latitude: latitude,
          longitude: longitude,
          timestamp: timestamp,
        );
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (ipfsHash) => AsyncData(ipfsHash),
    );
  }

  void reset() => state = const AsyncData(null);
}

final proofOfImpactRepositoryProvider = Provider<ProofOfImpactRepository>((ref) {
  return ProofOfImpactRepositoryImpl();
});

final proofOfImpactProvider = AsyncNotifierProvider<ProofOfImpactNotifier, String?>(
  ProofOfImpactNotifier.new,
);
