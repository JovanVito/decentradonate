import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/contract_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/proof_of_impact.dart';
import '../../domain/repositories/proof_of_impact_repository.dart';

class ProofOfImpactRepositoryImpl implements ProofOfImpactRepository {
  ProofOfImpactRepositoryImpl();

  @override
  Future<Either<Failure, String>> uploadProof({
    required String photoPath,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) async {
    try {
      if (!ContractConstants.isPinataConfigured) {
        return const Left(IpfsFailure(
          'Pinata JWT belum dikonfigurasi. Isi `pinataJwt` di contract_constants.dart.',
        ));
      }

      final file = File(photoPath);
      if (!await file.exists()) {
        return const Left(IpfsFailure('File foto tidak ditemukan di perangkat.'));
      }

      final bytes = await file.readAsBytes();
      final metadata = {
        'name': 'proof_impact_${timestamp.millisecondsSinceEpoch}.jpg',
        'keyvalues': {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'timestamp': timestamp.toIso8601String(),
        },
      };

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ContractConstants.pinataApiUrl),
      );

      request.headers['Authorization'] =
          'Bearer ${ContractConstants.pinataJwt}';

      final metadataJson = jsonEncode(metadata);
      request.fields['pinataMetadata'] = metadataJson;

      request.fields['pinataOptions'] = jsonEncode({
        'cidVersion': 1,
      });

      final stream = http.ByteStream(Stream.value(bytes));
      final length = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: p.basename(photoPath),
      );
      request.files.add(multipartFile);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        final ipfsHash = json['IpfsHash'] as String;
        return Right(ipfsHash);
      } else {
        return Left(IpfsFailure(
          'Upload ke IPFS gagal (HTTP ${response.statusCode}): $responseBody',
        ));
      }
    } on SocketException {
      return const Left(IpfsFailure(
        'Tidak ada koneksi internet. Periksa jaringan dan coba lagi.',
      ));
    } catch (e) {
      return Left(IpfsFailure('Gagal mengunggah bukti ke IPFS: $e'));
    }
  }

  @override
  Future<Either<Failure, ProofOfImpact?>> getLastProof() async {
    try {
      // Implementasi menyimpan/membaca dari local storage akan ada di Stage 4.
      // Saat ini return null karena belum ada persistensi lokal untuk proof.
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal membaca riwayat proof: $e'));
    }
  }
}
