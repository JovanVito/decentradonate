/// Bukti dampak (Proof-of-Impact) — foto + lokasi GPS sebagai bukti penggunaan dana.
/// Entity domain murni — TIDAK tahu apa-apa soal kamera, GPS, atau IPFS.
class ProofOfImpact {
  final String id;
  final String photoPath;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? ipfsHash;

  const ProofOfImpact({
    required this.id,
    required this.photoPath,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.ipfsHash,
  });

  /// Buat instance kosong untuk default value.
  factory ProofOfImpact.empty() => ProofOfImpact(
        id: '',
        photoPath: '',
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        ipfsHash: null,
      );

  /// Buat salinan dengan field yang berubah.
  ProofOfImpact copyWith({
    String? id,
    String? photoPath,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? ipfsHash,
  }) {
    return ProofOfImpact(
      id: id ?? this.id,
      photoPath: photoPath ?? this.photoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      ipfsHash: ipfsHash ?? this.ipfsHash,
    );
  }
}
