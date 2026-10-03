import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

class UserProfile {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.role = 'donatur',
  });

  bool get isOrganizer => role == 'organizer';
}

abstract class AuthRepository {
  Stream<String?> get authStateChanges;
  String? get currentUserId;
  Future<Either<Failure, UserProfile>> signUp({
    required String username,
    required String email,
    required String password,
  });
  Future<Either<Failure, UserProfile>> signIn({
    required String email,
    required String password,
  });
  Future<Either<Failure, void>> sendPasswordReset(String email);
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, UserProfile>> getProfile();
  Future<Either<Failure, UserProfile>> becomeOrganizer();
  Future<Either<Failure, void>> deleteAccount();
}
