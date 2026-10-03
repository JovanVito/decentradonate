import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_config.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  SupabaseClient? get _client => supabaseClient;

  @override
  Stream<String?> get authStateChanges =>
      _client?.auth.onAuthStateChange.map((event) => event.session?.user.id) ??
      const Stream<String?>.empty();

  @override
  String? get currentUserId => _client?.auth.currentUser?.id;

  Failure _failure(Object error) => UnexpectedFailure(error.toString());

  @override
  Future<Either<Failure, UserProfile>> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      return const Left(ConfigurationFailure('Supabase belum dikonfigurasi.'));
    }
    try {
      final response = await _client!.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: SupabaseConfig.emailRedirectTo,
        data: {'username': username},
      );
      final user = response.user;
      if (user == null) return const Left(UnexpectedFailure('Signup gagal.'));
      if (response.session != null) {
        await _client!.from('profiles').insert({
          'id': user.id,
          'username': username,
          'email': email,
        });
      }
      return Right(UserProfile(
        id: user.id,
        username: username,
        email: email,
      ));
    } catch (error) {
      return Left(_failure(error));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> signIn({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      return const Left(ConfigurationFailure('Supabase belum dikonfigurasi.'));
    }
    try {
      final response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) return const Left(UnexpectedFailure('Login gagal.'));
      return Right(UserProfile(
        id: user.id,
        username: (user.userMetadata?['username'] as String?) ?? email,
        email: user.email ?? email,
      ));
    } catch (error) {
      return Left(_failure(error));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordReset(String email) async {
    if (_client == null) {
      return const Left(ConfigurationFailure('Supabase belum dikonfigurasi.'));
    }
    try {
      await _client!.auth.resetPasswordForEmail(
        email,
        redirectTo: SupabaseConfig.emailRedirectTo,
      );
      return const Right(null);
    } catch (error) {
      return Left(_failure(error));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    if (_client == null) return const Right(null);
    try {
      await _client!.auth.signOut();
      return const Right(null);
    } catch (error) {
      return Left(_failure(error));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> getProfile() async {
    final user = _client?.auth.currentUser;
    if (user == null)
      return const Left(UnexpectedFailure('Sesi belum tersedia.'));
    try {
      final row = await _client!
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return Right(UserProfile(
        id: user.id,
        username: (row?['username'] as String?) ??
            (user.userMetadata?['username'] as String?) ??
            'Pengguna',
        email: (row?['email'] as String?) ?? user.email ?? '',
        phone: row?['phone'] as String?,
        avatarUrl: row?['avatar_url'] as String?,
        role: (row?['role'] as String?) ?? 'donatur',
      ));
    } catch (error) {
      return Left(_failure(error));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> becomeOrganizer() async {
    final user = _client?.auth.currentUser;
    if (user == null)
      return const Left(UnexpectedFailure('Sesi belum tersedia.'));
    try {
      await _client!
          .from('profiles')
          .update({'role': 'organizer'}).eq('id', user.id);
      return getProfile();
    } catch (error) {
      return Left(_failure(error));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    return const Left(UnexpectedFailure(
      'Penghapusan akun membutuhkan Edge Function Supabase dengan service role key.',
    ));
  }
}
