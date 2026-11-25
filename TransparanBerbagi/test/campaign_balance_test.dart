import 'package:decentradonate/features/campaigns/domain/campaign.dart';
import 'package:flutter_test/flutter_test.dart';

import 'campaign_fixture.dart';

void main() {
  test('computes available funds in integer rupiah', () {
    expect(Campaign.fromRow(campaignRow()).balance, 125000);
    expect(Campaign.fromRow(campaignRow(allocated: 250000)).balance, 0);
    expect(Campaign.fromRow(campaignRow(allocated: 0)).balance, 250000);
  });
}
