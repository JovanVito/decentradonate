/// Representasi error sebagai NILAI (bukan exception yang dilempar).
/// Ini dipakai bersama `dartz Either<Failure, T>`.
///
/// KENAPA PENTING untuk checkpoint UTS-mu:
/// Requirement dosen bilang "aplikasi harus menampilkan loading, empty,
/// dan error state" serta "tidak boleh fatal error saat koneksi lambat".
/// Kalau kita pakai try-catch biasa yang menyebar di banyak tempat, gampang
/// ada satu titik yang lupa di-catch → app crash. Dengan Either, compiler
/// MEMAKSA kita menangani kedua kemungkinan (Left = gagal, Right = sukses)
/// di setiap pemanggilan use case.
abstract class Failure {
  final String message;
  const Failure(this.message);
}

/// Tidak ada koneksi internet sama sekali.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Tidak ada koneksi internet.']);
}

/// RPC node (Alchemy) tidak bisa dihubungi / timeout.
class RpcFailure extends Failure {
  const RpcFailure([super.message = 'Gagal terhubung ke jaringan blockchain.']);
}

/// Konfigurasi aplikasi (RPC URL/contract address/ABI) belum diisi dengan
/// benar — masih placeholder. SENGAJA dipisah dari RpcFailure karena
/// solusinya beda: RpcFailure → user disuruh cek koneksi internetnya.
/// ConfigurationFailure → DEVELOPER (kamu) yang harus mengisi
/// contract_constants.dart / donation_abi.json, bukan salah user aplikasi.
class ConfigurationFailure extends Failure {
  const ConfigurationFailure([super.message = 'Konfigurasi aplikasi belum lengkap.']);
}

/// Transaksi ditolak oleh smart contract (mis. saldo tidak cukup).
class TransactionFailure extends Failure {
  const TransactionFailure([super.message = 'Transaksi gagal diproses.']);
}

/// Kegagalan baca/tulis database lokal (sqflite).
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Gagal mengakses data lokal.']);
}

/// Kegagalan spesifik wallet: mnemonic tidak valid, gagal derive private key, dll.
/// Dipisah dari CacheFailure karena sumber masalahnya beda (input user yang
/// salah vs storage yang rusak) — pesan errornya juga harus beda ke user.
class WalletFailure extends Failure {
  const WalletFailure([super.message = 'Terjadi kesalahan pada wallet.']);
}

/// Izin (Camera/GPS) ditolak pengguna.
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Izin akses ditolak.']);
}

/// Upload ke IPFS (Pinata) gagal.
class IpfsFailure extends Failure {
  const IpfsFailure([super.message = 'Gagal mengunggah bukti ke IPFS.']);
}

/// Fallback untuk error yang tidak terduga.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Terjadi kesalahan tak terduga.']);
}
