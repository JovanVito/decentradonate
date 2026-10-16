import 'package:dartz/dartz.dart';
import 'package:decentradonate/core/errors/failures.dart';
import 'package:decentradonate/features/wallet/domain/entities/wallet_contact.dart';
import 'package:decentradonate/features/wallet/domain/repositories/contact_repository.dart';
import 'package:decentradonate/features/wallet/presentation/providers/contact_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repository in-memory yang MENIRU perilaku SQLite (map + auto increment).
/// Dipakai untuk menguji alur CRUD notifier tanpa perlu device/emulator.
class InMemoryContactRepository implements ContactRepository {
  final _rows = <int, WalletContact>{};
  int _seq = 0;

  @override
  Future<Either<Failure, List<WalletContact>>> getContacts() async {
    final list = _rows.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return Right(list);
  }

  @override
  Future<Either<Failure, WalletContact>> insertContact(
      WalletContact contact) async {
    final id = ++_seq;
    final saved = contact.copyWith(id: id);
    _rows[id] = saved;
    return Right(saved);
  }

  @override
  Future<Either<Failure, void>> updateContact(WalletContact contact) async {
    if (contact.id == null || !_rows.containsKey(contact.id)) {
      return const Left(CacheFailure('Kontak tidak ditemukan.'));
    }
    _rows[contact.id!] = contact;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteContact(int id) async {
    _rows.remove(id);
    return const Right(null);
  }
}

void main() {
  late InMemoryContactRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = InMemoryContactRepository();
    container = ProviderContainer(overrides: [
      contactRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  test('CREATE lalu READ kontak baru', () async {
    final notifier = container.read(contactProvider.notifier);

    final error = await notifier.addContact(
      name: 'Budi',
      address: '0xAbC1234567890aBcDeF1234567890aBcDeF12345',
    );
    expect(error, isNull);

    final state = container.read(contactProvider).value!;
    expect(state.length, 1);
    expect(state.first.name, 'Budi');
    expect(state.first.id, isNotNull);
  });

  test('UPDATE mengubah nama tanpa mengubah alamat', () async {
    final notifier = container.read(contactProvider.notifier);
    await notifier.addContact(
      name: 'Budi',
      address: '0xAbC1234567890aBcDeF1234567890aBcDeF12345',
    );
    final original = container.read(contactProvider).value!.first;

    await notifier.editContact(original.copyWith(name: 'Budi Santoso'));

    final updated = container.read(contactProvider).value!.first;
    expect(updated.name, 'Budi Santoso');
    expect(updated.address, original.address);
  });

  test('DELETE menghapus kontak dari penyimpanan', () async {
    final notifier = container.read(contactProvider.notifier);
    await notifier.addContact(name: 'Budi', address: '0x111111111111');
    final id = container.read(contactProvider).value!.first.id!;

    await notifier.removeContact(id);

    expect(container.read(contactProvider).value, isEmpty);
  });

  test('PERSISTENSI: data tetap ada saat provider dibuat ulang', () async {
    // Simulasi "tutup lalu buka aplikasi": container lama dibuang,
    // container baru dibuat dengan repository yang SAMA (seperti file .db).
    var notifier = container.read(contactProvider.notifier);
    await notifier.addContact(name: 'Siti', address: '0x222222222222');

    final reopened = ProviderContainer(overrides: [
      contactRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(reopened.dispose);

    final reloaded = await reopened.read(contactProvider.future);
    expect(reloaded.length, 1);
    expect(reloaded.first.name, 'Siti');
  });

  test('entity toMap/fromMap konsisten (siap tulis-baca SQLite)', () {
    final contact = WalletContact(
      id: 7,
      name: 'Rina',
      address: '0x333333333333',
      addedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );

    final restored = WalletContact.fromMap(contact.toMap());
    expect(restored.id, contact.id);
    expect(restored.name, contact.name);
    expect(restored.address, contact.address);
    expect(restored.addedAt, contact.addedAt);
  });
}
