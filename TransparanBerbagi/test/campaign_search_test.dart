import 'package:decentradonate/features/campaigns/domain/campaign.dart';
import 'package:flutter_test/flutter_test.dart';

import 'campaign_fixture.dart';

void main() {
  final campaign = Campaign.fromRow(campaignRow());
  test('matches title, organizer and category without case sensitivity', () {
    for (final query in [' BUKU ', 'taman belajar', 'PENDIDIKAN', '  ']) {
      expect(campaign.matches(query), isTrue, reason: query);
    }
    expect(campaign.matches('kesehatan'), isFalse);
    expect(campaign.matches('Bantu menyediakan'), isFalse);
  });
}
