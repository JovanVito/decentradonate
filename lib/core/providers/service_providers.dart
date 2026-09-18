import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/proof_of_impact/data/repositories/proof_of_impact_repository_impl.dart';
import '../../features/proof_of_impact/domain/repositories/proof_of_impact_repository.dart';
import '../../services/wallet_service.dart';
import '../../services/web3_service.dart';

/// Provider untuk service LINTAS FITUR — dipakai oleh fitur `wallet` DAN
/// `donation` sama-sama (donasi butuh baca mnemonic wallet untuk sign
/// transaksi, dan butuh Web3Service untuk kirim transaksi).
///
/// SENGAJA diletakkan di `core/providers`, BUKAN di dalam folder fitur
/// manapun. Kalau ini ditaruh di `features/wallet/presentation/providers`
/// (seperti sebelumnya), fitur `donation` jadi "bergantung" ke internal
/// fitur `wallet` — melanggar prinsip "tiap fitur berdiri sendiri" yang
/// kita pegang sejak Stage 1.
final walletServiceProvider = Provider<WalletService>((ref) => WalletService());

final web3ServiceProvider = Provider<Web3Service>((ref) => Web3Service());

final proofOfImpactRepositoryProvider = Provider<ProofOfImpactRepository>((ref) {
  return ProofOfImpactRepositoryImpl();
});
