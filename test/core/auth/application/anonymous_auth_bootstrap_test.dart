import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/application/anonymous_auth_bootstrap.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';

void main() {
  group('AnonymousAuthBootstrap', () {
    test('returns the current user when one already exists', () async {
      const currentUser = AppUser(id: 'existing-user', isAnonymous: true);
      final authRepository = _FakeAuthRepository(currentAuthUser: currentUser);

      final user = await AnonymousAuthBootstrap.ensureSignedIn(authRepository);

      expect(user, same(currentUser));
      expect(authRepository.signInAnonymouslyCallCount, isZero);
    });

    test('signs in anonymously when no current user exists', () async {
      const signedInUser = AppUser(id: 'anonymous-user', isAnonymous: true);
      final authRepository = _FakeAuthRepository(signedInUser: signedInUser);

      final user = await AnonymousAuthBootstrap.ensureSignedIn(authRepository);

      expect(user, same(signedInUser));
      expect(authRepository.signInAnonymouslyCallCount, 1);
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.currentAuthUser,
    AppUser? signedInUser,
  }) : signedInUser = signedInUser ??
            const AppUser(id: 'signed-in-user', isAnonymous: true);

  final AppUser? currentAuthUser;
  final AppUser signedInUser;
  int signInAnonymouslyCallCount = 0;

  @override
  Future<AppUser?> currentUser() async => currentAuthUser;

  @override
  Future<AppUser> signInAnonymously() async {
    signInAnonymouslyCallCount += 1;
    return signedInUser;
  }

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() {
    return Stream<AppUser?>.value(currentAuthUser);
  }
}
