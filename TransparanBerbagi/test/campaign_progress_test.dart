import 'package:decentradonate/features/campaigns/domain/campaign.dart';
import 'package:flutter_test/flutter_test.dart';

import 'campaign_fixture.dart';

void main() {
  test('tracks partial fundraising and clamps overfunded campaigns', () {
    expect(Campaign.fromRow(campaignRow()).progress, 0.5);
    expect(Campaign.fromRow(campaignRow(raised: 700000)).progress, 1.0);
    expect(Campaign.fromRow(campaignRow(raised: 0, allocated: 0)).progress, 0);
  });

  test('never divides by zero for a malformed legacy target', () {
    expect(Campaign.fromRow(campaignRow(target: 0)).progress, 0);
  });
}
