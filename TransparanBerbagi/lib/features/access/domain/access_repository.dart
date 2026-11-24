enum AccountRole { donor, organizer, admin }

abstract interface class AccessRepository {
  Stream<void> get sessionChanges;
  Future<AccountRole?> currentRole();
  Future<void> sendCode(String email, {required bool allowSignup});
  Future<void> verifyCode(String email, String code);
  Future<void> signOut();
}
