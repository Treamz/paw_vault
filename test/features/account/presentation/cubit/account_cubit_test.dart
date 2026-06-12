import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/account_auth_repository.dart';
import 'package:paw_vault/features/account/presentation/cubit/account_cubit.dart';

void main() {
  group('AccountCubit', () {
    test('reflects the watched current user', () async {
      final repository = _FakeAccountAuthRepository();
      final cubit = AccountCubit(repository);

      repository.emitUser(
        const AppUser(id: 'u1', isAnonymous: false, email: 'a@b.com'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.user?.email, 'a@b.com');
      expect(cubit.state.isSignedIn, isTrue);

      await cubit.close();
    });

    test('an anonymous user is not considered signed in', () async {
      final repository = _FakeAccountAuthRepository();
      final cubit = AccountCubit(repository);

      repository.emitUser(const AppUser(id: 'anon', isAnonymous: true));
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isSignedIn, isFalse);

      await cubit.close();
    });

    test('registerWithEmail authenticates and sets the user', () async {
      final repository = _FakeAccountAuthRepository();
      final cubit = AccountCubit(repository);
      final states = <AccountState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.registerWithEmail(email: 'a@b.com', password: 'secret123');

      expect(repository.registeredEmail, 'a@b.com');
      expect(
          states.any((s) => s.status == AccountStatus.authenticating), isTrue);
      expect(cubit.state.status, AccountStatus.idle);
      expect(cubit.state.user?.email, 'a@b.com');

      await sub.cancel();
      await cubit.close();
    });

    test('signInWithGoogle authenticates through the repository', () async {
      final repository = _FakeAccountAuthRepository();
      final cubit = AccountCubit(repository);

      await cubit.signInWithGoogle();

      expect(repository.googleCallCount, 1);
      expect(cubit.state.isSignedIn, isTrue);

      await cubit.close();
    });

    test('emits failure when authentication throws', () async {
      final repository = _FakeAccountAuthRepository(throwsOnAuth: true);
      final cubit = AccountCubit(repository);

      await cubit.signInWithEmail(email: 'a@b.com', password: 'bad');

      expect(cubit.state.status, AccountStatus.failure);
      expect(cubit.state.errorMessage, contains('auth failed'));

      await cubit.close();
    });

    test('signOut delegates to the repository', () async {
      final repository = _FakeAccountAuthRepository();
      final cubit = AccountCubit(repository);

      await cubit.signOut();

      expect(repository.signOutCallCount, 1);

      await cubit.close();
    });
  });
}

class _FakeAccountAuthRepository implements AccountAuthRepository {
  _FakeAccountAuthRepository({this.throwsOnAuth = false});

  final bool throwsOnAuth;
  final _controller = StreamController<AppUser?>.broadcast();

  String? registeredEmail;
  int googleCallCount = 0;
  int signOutCallCount = 0;

  void emitUser(AppUser? user) => _controller.add(user);

  AppUser _account({String? email}) =>
      AppUser(id: 'account-1', isAnonymous: false, email: email);

  @override
  Stream<AppUser?> watchCurrentUser() => _controller.stream;

  @override
  Future<AppUser?> currentUser() async => null;

  @override
  Future<AppUser> signInAnonymously() async =>
      const AppUser(id: 'anon', isAnonymous: true);

  @override
  Future<void> signOut() async {
    signOutCallCount++;
  }

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    if (throwsOnAuth) throw StateError('auth failed');
    registeredEmail = email;
    return _account(email: email);
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (throwsOnAuth) throw StateError('auth failed');
    return _account(email: email);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    if (throwsOnAuth) throw StateError('auth failed');
    googleCallCount++;
    return _account();
  }

  @override
  Future<AppUser> signInWithApple() async {
    if (throwsOnAuth) throw StateError('auth failed');
    return _account();
  }
}
