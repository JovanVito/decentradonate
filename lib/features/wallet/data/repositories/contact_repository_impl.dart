import 'package:dartz/dartz.dart';
import '../../../../core/database/local_store.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/wallet_contact.dart';
import '../../domain/repositories/contact_repository.dart';

/// Implementasi CRUD kontak wallet (Local Data & Persistence).
///
/// Backend penyimpanan ditentukan oleh `LocalStore`:
/// - Android/iOS/desktop: SQLite (`sqflite`).
/// - Web (Chrome): `shared_preferences` (localStorage).
///
/// Pemetaan CRUD:
/// CREATE = insertContact, READ = getContacts,
/// UPDATE = updateContact, DELETE = deleteContact.
class ContactRepositoryImpl implements ContactRepository {
  final LocalStore _store;

  ContactRepositoryImpl([LocalStore? store]) : _store = store ?? LocalStore();

  @override
  Future<Either<Failure, List<WalletContact>>> getContacts() async {
    try {
      final rows = await _store.readAll();
      return Right(rows.map(WalletContact.fromMap).toList());
    } catch (e) {
      return Left(CacheFailure('Gagal membaca kontak: $e'));
    }
  }

  @override
  Future<Either<Failure, WalletContact>> insertContact(
      WalletContact contact) async {
    try {
      final id = await _store.insert(contact.toMap());
      return Right(contact.copyWith(id: id));
    } catch (e) {
      return Left(CacheFailure('Gagal menyimpan kontak: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateContact(WalletContact contact) async {
    try {
      if (contact.id == null) {
        return const Left(CacheFailure('Kontak tidak memiliki id.'));
      }
      await _store.update(contact.id!, contact.toMap());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal memperbarui kontak: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteContact(int id) async {
    try {
      await _store.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal menghapus kontak: $e'));
    }
  }
}
