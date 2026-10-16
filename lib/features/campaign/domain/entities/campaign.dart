import '../../../../core/errors/failures.dart';

class CampaignModelException implements Exception {
  final String message;
  const CampaignModelException(this.message);
  @override
  String toString() => message;
}

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

  factory Campaign.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw CampaignModelException('Field campaign tidak valid: $key');
      }
      return value;
    }

    num requiredNumber(String key) {
      final value = json[key];
      if (value is! num) {
        throw CampaignModelException('Field campaign tidak valid: $key');
      }
      return value;
    }

    return Campaign(
      id: requiredString('id'),
      title: requiredString('title'),
      description: requiredString('description'),
      organizer: requiredString('organizer_id'),
      targetAmount: requiredNumber('target_amount').toDouble(),
      collectedAmount: (json['collected_amount'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'organizer_id': organizer,
        'target_amount': targetAmount,
        'collected_amount': collectedAmount,
        'image_url': imageUrl,
      };

  Campaign copyWith(
          {String? id,
          String? title,
          String? description,
          String? organizer,
          double? targetAmount,
          double? collectedAmount,
          String? imageUrl}) =>
      Campaign(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        organizer: organizer ?? this.organizer,
        targetAmount: targetAmount ?? this.targetAmount,
        collectedAmount: collectedAmount ?? this.collectedAmount,
        imageUrl: imageUrl ?? this.imageUrl,
      );
}

class CampaignApiFailure extends Failure {
  const CampaignApiFailure(super.message);
}

List<Campaign> dummyCampaigns() => const [
      Campaign(
          id: '0',
          title: 'Bantu Renovasi Sekolah Darurat di Cianjur',
          description: 'Dana untuk material bangunan dan upah tukang setempat.',
          organizer: '0xAbC1...9F3d',
          targetAmount: 5,
          collectedAmount: 2.35,
          imageUrl: 'assets/images/foto1.png'),
      Campaign(
          id: '1',
          title: 'Sumur Bor untuk Desa Terpencil',
          description: 'Menyediakan akses air bersih bagi 40 keluarga.',
          organizer: '0x77Ef...11Aa',
          targetAmount: 3,
          collectedAmount: 3,
          imageUrl: 'assets/images/foto2.png'),
      Campaign(
          id: '2',
          title: 'Bantuan Alat Belajar Anak Yatim',
          description: 'Pengadaan buku dan alat tulis untuk 100 anak.',
          organizer: '0x902C...44Fe',
          targetAmount: 1.5,
          collectedAmount: 0.4,
          imageUrl: 'assets/images/foto3.png'),
    ];
