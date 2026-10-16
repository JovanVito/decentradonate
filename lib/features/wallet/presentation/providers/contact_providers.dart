import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/contact_repository_impl.dart';
import '../../domain/entities/wallet_contact.dart';
import '../../domain/repositories/contact_repository.dart';

/// Repository kontak wallet (LOCAL — SQLite).
final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepositoryImpl();
});

/// AsyncNotifier CRUD kontak. Setiap aksi memanggil repository lalu
/// menyegarkan state dari database, sehingga UI selalu sinkron dengan
/// data yang benar-benar tersimpan di disk.
class ContactNotifier extends AsyncNotifier<List<WalletContact>> {
  @override
  Future<List<WalletContact>> build() => _load();

  Future<List<WalletContact>> _load() async {
    final result = await ref.read(contactRepositoryProvider).getContacts();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (contacts) => contacts,
    );
  }

  /// CREATE
  Future<String?> addContact({
    required String name,
    required String address,
  }) async {
    final contact = WalletContact(
      name: name.trim(),
      address: address.trim(),
      addedAt: DateTime.now(),
    );
    final result =
        await ref.read(contactRepositoryProvider).insertContact(contact);
    return result.fold(
      (failure) => failure.message,
      (_) async {
        state = AsyncData(await _load());
        return null;
      },
    );
  }

  /// UPDATE
  Future<String?> editContact(WalletContact contact) async {
    final result =
        await ref.read(contactRepositoryProvider).updateContact(contact);
    return result.fold(
      (failure) => failure.message,
      (_) async {
        state = AsyncData(await _load());
        return null;
      },
    );
  }

  /// DELETE
  Future<String?> removeContact(int id) async {
    final result = await ref.read(contactRepositoryProvider).deleteContact(id);
    return result.fold(
      (failure) => failure.message,
      (_) async {
        state = AsyncData(await _load());
        return null;
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final contactProvider =
    AsyncNotifierProvider<ContactNotifier, List<WalletContact>>(
  ContactNotifier.new,
);
