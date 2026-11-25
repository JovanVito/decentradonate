class Campaign {
  const Campaign({
    required this.id,
    required this.title,
    required this.organizer,
    required this.category,
    required this.story,
    required this.target,
    required this.raised,
    required this.allocated,
    required this.donors,
  });

  factory Campaign.fromRow(Map<String, dynamic> row) => Campaign(
    id: row['id'] as String,
    title: row['title'] as String,
    organizer: row['organizer_name'] as String,
    category: row['category'] as String,
    story: row['story'] as String,
    target: row['target_amount'] as int,
    raised: row['raised_amount'] as int,
    allocated: row['allocated_amount'] as int,
    donors: row['donor_count'] as int,
  );

  final String id, title, organizer, category, story;
  final int target, raised, allocated, donors;

  int get balance => raised - allocated;
  double get progress => target <= 0 ? 0 : (raised / target).clamp(0, 1);

  bool matches(String search) {
    final query = search.trim().toLowerCase();
    return [
      title,
      organizer,
      category,
    ].any((value) => value.toLowerCase().contains(query));
  }
}

class PublishedAllocation {
  const PublishedAllocation({
    required this.description,
    required this.category,
    required this.amount,
    required this.publishedAt,
  });

  factory PublishedAllocation.fromRow(Map<String, dynamic> row) =>
      PublishedAllocation(
        description: row['description'] as String,
        category: row['category'] as String,
        amount: row['amount'] as int,
        publishedAt: DateTime.parse(row['published_at'] as String),
      );

  final String description, category;
  final int amount;
  final DateTime publishedAt;
}
