/// Entity domain murni — TIDAK tahu apa-apa soal JSON, SQLite, atau blockchain.
class Campaign {
  final String id;
  final String title;
  final String description;
  final String organizer;
  final double targetAmount;
  final double collectedAmount;
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

List<Campaign> dummyCampaigns() => const [
      Campaign(
        id: '0',
        title: 'Bantu Renovasi Sekolah Darurat di Cianjur',
        description: 'Dana untuk material bangunan dan upah tukang setempat.',
        organizer: '0xAbC1...9F3d',
        targetAmount: 5,
        collectedAmount: 2.35,
        imageUrl: 'assets/images/foto1.png',
      ),
      Campaign(
        id: '1',
        title: 'Sumur Bor untuk Desa Terpencil',
        description: 'Menyediakan akses air bersih bagi 40 keluarga.',
        organizer: '0x77Ef...11Aa',
        targetAmount: 3,
        collectedAmount: 3,
        imageUrl: 'assets/images/foto2.png',
      ),
      Campaign(
        id: '2',
        title: 'Bantuan Alat Belajar Anak Yatim',
        description: 'Pengadaan buku dan alat tulis untuk 100 anak.',
        organizer: '0x902C...44Fe',
        targetAmount: 1.5,
        collectedAmount: 0.4,
        imageUrl: 'assets/images/foto3.png',
      ),
      Campaign(
        id: '3',
        title: 'Pembangunan Poskesdes Desa Cibitung',
        description: 'Membangun pos kesehatan desa dengan fasilitas lengkap.',
        organizer: '0x123A...567B',
        targetAmount: 10,
        collectedAmount: 7.5,
        imageUrl: 'assets/images/foto4.png',
      ),
      Campaign(
        id: '4',
        title: 'Bantuan Benih Pertanian Petani Lembang',
        description: 'Pemberian benih unggul untuk meningkatkan hasil panen.',
        organizer: '0x987C...321D',
        targetAmount: 7,
        collectedAmount: 3.2,
        imageUrl: 'assets/images/foto5.png',
      ),
      Campaign(
        id: '5',
        title: 'Rumah Ibadah Desa Margahayu',
        description: 'Pembangunan masjid dengan fasilitas khatam Quran.',
        organizer: '0xDEF4...567A',
        targetAmount: 15,
        collectedAmount: 12.8,
        imageUrl: 'assets/images/foto6.png',
      ),
      Campaign(
        id: '6',
        title: 'Bantuan Kuliah Anak Papua',
        description: 'Biaya pendidikan untuk 20 anak Papua mampu.',
        organizer: '0xA1B2...C3D4',
        targetAmount: 8,
        collectedAmount: 5.1,
        imageUrl: 'assets/images/foto6.png',
      ),
    ];
