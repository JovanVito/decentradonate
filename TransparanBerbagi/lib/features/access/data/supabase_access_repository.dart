import 'package:decentradonate/features/access/domain/access_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accessRepositoryProvider = Provider<AccessRepository?>((ref) => null);

class SupabaseAccessRepository implements AccessRepository {
  const SupabaseAccessRepository(this.client);

  final SupabaseClient client;

  @override
  Stream<void> get sessionChanges => client.auth.onAuthStateChange.map((_) {});

  @override
  Future<AccountRole?> currentRole() async {
    final id = client.auth.currentUser?.id;
    if (id == null) return null;
    final profile = await client
        .from('profiles')
        .select('role')
        .eq('id', id)
        .single();
    final role = AccountRole.values.byName(profile['role'] as String);
    if (role != AccountRole.organizer) return role;
    final organizer = await client
        .from('organizer_profiles')
        .select('status')
        .eq('user_id', id)
        .maybeSingle();
    return organizer?['status'] == 'approved' ? role : null;
  }

  @override
  Future<void> sendCode(String email, {required bool allowSignup}) =>
      client.auth.signInWithOtp(email: email, shouldCreateUser: allowSignup);

  @override
  Future<void> verifyCode(String email, String code) async {
    await client.auth.verifyOTP(email: email, token: code, type: OtpType.email);
  }

  @override
  Future<void> signOut() => client.auth.signOut(scope: SignOutScope.local);
}
