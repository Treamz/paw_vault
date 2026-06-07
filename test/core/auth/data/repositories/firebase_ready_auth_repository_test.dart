import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:paw_vault/core/auth/data/repositories/firebase_ready_auth_repository.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';

void main() {
  group('FirebaseReadyAuthRepository', () {
    test('watches current user through the data source', () async {
      const user = AppUser(id: 'user-1', isAnonymous: true);
      final dataSource = _FakeFirebaseAuthDataSource(watchedUser: user);
      final repository = FirebaseReadyAuthRepository(dataSource);

      final result = await repository.watchCurrentUser().first;

      expect(result, user);
      expect(dataSource.watchCurrentUserCallCount, 1);
    });

    test('returns current user through the data source', () async {
      const user = AppUser(id: 'user-1', isAnonymous: true);
      final dataSource = _FakeFirebaseAuthDataSource(currentUserValue: user);
      final repository = FirebaseReadyAuthRepository(dataSource);

      final result = await repository.currentUser();

      expect(result, user);
      expect(dataSource.currentUserCallCount, 1);
    });

    test('signs in anonymously through the data source', () async {
      const user = AppUser(id: 'user-1', isAnonymous: true);
      final dataSource = _FakeFirebaseAuthDataSource(signedInUser: user);
      final repository = FirebaseReadyAuthRepository(dataSource);

      final result = await repository.signInAnonymously();

      expect(result, user);
      expect(dataSource.signInAnonymouslyCallCount, 1);
    });

    test('signs out through the data source', () async {
      final dataSource = _FakeFirebaseAuthDataSource();
      final repository = FirebaseReadyAuthRepository(dataSource);

      await repository.signOut();

      expect(dataSource.signOutCallCount, 1);
    });
  });
}

class _FakeFirebaseAuthDataSource implements FirebaseAuthDataSource {
  _FakeFirebaseAuthDataSource({
    this.watchedUser,
    this.currentUserValue,
    this.signedInUser = const AppUser(id: 'signed-in-user', isAnonymous: true),
  });

  final AppUser? watchedUser;
  final AppUser? currentUserValue;
  final AppUser signedInUser;

  int watchCurrentUserCallCount = 0;
  int currentUserCallCount = 0;
  int signInAnonymouslyCallCount = 0;
  int signOutCallCount = 0;

  @override
  Future<AppUser?> currentUser() async {
    currentUserCallCount++;
    return currentUserValue;
  }

  @override
  Future<AppUser> signInAnonymously() async {
    signInAnonymouslyCallCount++;
    return signedInUser;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
  }

  @override
  Stream<AppUser?> watchCurrentUser() {
    watchCurrentUserCallCount++;
    return Stream<AppUser?>.value(watchedUser);
  }
}
