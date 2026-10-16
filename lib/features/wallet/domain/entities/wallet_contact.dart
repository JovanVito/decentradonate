/// Entity kontak wallet yang disimpan secara LOKAL (SQLite).
///
/// Disimpan lokal karena ini data pribadi pengguna yang tidak perlu dikirim
/// ke server, dan harus tetap ada saat perangkat offline.
class WalletContact {
  final int? id;
  final String name;
  final String address;
  final DateTime addedAt;

  const WalletContact({
    this.id,
    required this.name,
    required this.address,
    required this.addedAt,
  });

  WalletContact copyWith({
    int? id,
    String? name,
    String? address,
    DateTime? addedAt,
  }) {
    return WalletContact(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Konversi ke Map untuk ditulis ke SQLite.
  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'address': address,
        'added_at': addedAt.millisecondsSinceEpoch,
      };

  /// Konversi dari Map hasil query SQLite.
  factory WalletContact.fromMap(Map<String, Object?> map) => WalletContact(
        id: map['id'] as int?,
        name: map['name'] as String,
        address: map['address'] as String,
        addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
      );
}
