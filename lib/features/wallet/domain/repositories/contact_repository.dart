import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_contact.dart';

/// Kontrak CRUD kontak wallet. Domain tidak tahu SQLite sama sekali —
/// kalau nanti mau ganti ke Hive/Isar, cukup buat implementasi baru.
abstract class ContactRepository {
  Future<Either<Failure, List<WalletContact>>> getContacts();
  Future<Either<Failure, WalletContact>> insertContact(WalletContact contact);
  Future<Either<Failure, void>> updateContact(WalletContact contact);
  Future<Either<Failure, void>> deleteContact(int id);
}
