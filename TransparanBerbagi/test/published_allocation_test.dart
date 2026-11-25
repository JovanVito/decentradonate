import 'package:decentradonate/features/campaigns/domain/campaign.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'keeps corrections negative and parses publication time as an instant',
    () {
      final allocation = PublishedAllocation.fromRow({
        'description': 'Koreksi nilai pengadaan',
        'category': 'Buku',
        'amount': -12500,
        'published_at': '2026-11-25T07:00:00+07:00',
      });
      expect(allocation.amount, -12500);
      expect(allocation.publishedAt, DateTime.utc(2026, 11, 25));
      expect(allocation.description, 'Koreksi nilai pengadaan');
    },
  );
}
