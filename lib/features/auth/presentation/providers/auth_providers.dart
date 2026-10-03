import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authSessionProvider = StreamProvider<String?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final profileProvider = FutureProvider<UserProfile>((ref) async {
  final result = await ref.watch(authRepositoryProvider).getProfile();
  return result.fold((failure) => throw Exception(failure.message), (profile) => profile);
});
