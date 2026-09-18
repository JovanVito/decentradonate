/// Entity domain murni — TIDAK tahu apa-apa soal JSON, SQLite, atau blockchain.
/// Ini representasi "apa itu Campaign" secara konsep, dipakai di seluruh app.
///
/// Sengaja plain Dart class (bukan @freezed) di Stage 1 supaya proyek bisa
/// langsung `flutter run` tanpa build_runner. Model data nyata (dengan
/// fromJson/fromMap untuk smart contract & sqflite) akan dibuat di Stage 2
/// sebagai `CampaignModel extends Campaign` di layer data/models.
class Campaign {
  final String id; // akan diisi dari on-chain campaign ID (uint256 -> string)
  final String title;
  final String description;
  final String organizer; // wallet address pembuat kampanye
  final double targetAmount; // dalam MATIC
  final double collectedAmount; // dalam MATIC
  final String? imageUrl;

  const Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.organizer,
    required this.targetAmount,
    required this.collectedAmount,
    this.imageUrl,
  });

  double get progressPercent =>
      targetAmount <= 0 ? 0 : (collectedAmount / targetAmount).clamp(0, 1);

  Campaign copyWith({
    String? id,
    String? title,
    String? description,
    String? organizer,
    double? targetAmount,
    double? collectedAmount,
    String? imageUrl,
  }) {
    return Campaign(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      organizer: organizer ?? this.organizer,
      targetAmount: targetAmount ?? this.targetAmount,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

/// Data dummy untuk keperluan demo UI di Stage 1, SEBELUM integrasi
/// smart contract nyata masuk di Stage 2. Hapus/ganti saat repository
/// data-layer sudah terhubung ke web3dart.
///
/// CATATAN Langkah 2.3: id di sini SENGAJA mulai dari '0' (bukan '1')
/// supaya selaras dengan indexing array `campaigns` di Solidity yang
/// juga mulai dari 0. Ini TIDAK berarti otomatis tersinkron dengan
/// contract asli — kamu tetap harus membuat campaign sungguhan di
/// contract (lihat blockchain/DEPLOY_GUIDE.md Langkah 7) sebelum
/// tombol "Donasi Sekarang" di sini benar-benar berhasil on-chain.
List<Campaign> dummyCampaigns() => const [
      Campaign(
        id: '0',
        title: 'Bantu Renovasi Sekolah Darurat di Cianjur',
        description:
            'Dana akan digunakan untuk membeli material bangunan dan upah tukang setempat.',
        organizer: '0xAbC1...9F3d',
        targetAmount: 5,
        collectedAmount: 2.35,
      ),
      Campaign(
        id: '1',
        title: 'Sumur Bor untuk Desa Terpencil',
        description: 'Menyediakan akses air bersih bagi 40 keluarga.',
        organizer: '0x77Ef...11Aa',
        targetAmount: 3,
        collectedAmount: 3,
      ),
      Campaign(
        id: '2',
        title: 'Bantuan Alat Belajar Anak Yatim',
        description: 'Pengadaan buku dan alat tulis untuk 100 anak.',
        organizer: '0x902C...44Fe',
        targetAmount: 1.5,
        collectedAmount: 0.4,
      ),
    ];
