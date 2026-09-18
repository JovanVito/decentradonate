/// Exception dilempar HANYA di layer data (datasource), lalu ditangkap
/// oleh repository dan diubah menjadi `Failure` (lihat failures.dart)
/// sebelum sampai ke domain/presentation.
///
/// Alur: Datasource throws Exception -> Repository catches -> returns Left(Failure)
class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server error']);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache error']);
}

class RpcException implements Exception {
  final String message;
  RpcException([this.message = 'RPC error']);
}
