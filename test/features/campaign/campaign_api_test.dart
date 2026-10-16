import 'package:decentradonate/core/errors/failures.dart';
import 'package:decentradonate/features/campaign/data/repositories/campaign_repository_impl.dart';
import 'package:decentradonate/features/campaign/domain/entities/campaign.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> validJson() => {
      'id': 'campaign-1',
      'title': 'Bantuan Air Bersih',
      'description': 'Pembangunan sumur untuk warga.',
      'organizer_id': 'user-1',
      'target_amount': 5,
      'collected_amount': 2.5,
      'image_url': null,
    };

void main() {
  test('model valid dapat dibuat dari JSON', () {
    final model = Campaign.fromJson(validJson());
    expect(model.id, 'campaign-1');
    expect(model.targetAmount, 5);
    expect(model.collectedAmount, 2.5);
  });

  test('model invalid menolak field wajib yang hilang', () {
    final json = validJson()..remove('title');
    expect(
        () => Campaign.fromJson(json), throwsA(isA<CampaignModelException>()));
  });

  test('API sukses mengembalikan campaign', () async {
    final repository = CampaignRepositoryImpl(
      fallbackToDummy: false,
      fetchRows: () async => [validJson()],
    );
    final result = await repository.getCampaigns();
    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => []).single.title, 'Bantuan Air Bersih');
  });

  test('API mengembalikan data kosong', () async {
    final repository = CampaignRepositoryImpl(
      fallbackToDummy: false,
      fetchRows: () async => [],
    );
    final result = await repository.getCampaigns();
    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => []), isEmpty);
  });

  test('HTTP/backend gagal menghasilkan NetworkFailure', () async {
    final repository = CampaignRepositoryImpl(
      fallbackToDummy: false,
      fetchRows: () async => throw Exception('connection refused'),
    );
    final result = await repository.getCampaigns();
    expect(result.isLeft(), isTrue);
    expect(
        result.swap().getOrElse(() => const UnexpectedFailure('')).runtimeType,
        NetworkFailure);
  });

  test('JSON rusak menghasilkan CampaignApiFailure', () async {
    final json = validJson()..['target_amount'] = 'not-a-number';
    final repository = CampaignRepositoryImpl(
      fallbackToDummy: false,
      fetchRows: () async => [json],
    );
    final result = await repository.getCampaigns();
    expect(result.isLeft(), isTrue);
    expect(
        result.swap().getOrElse(() => const UnexpectedFailure('')).runtimeType,
        CampaignApiFailure);
  });
}
