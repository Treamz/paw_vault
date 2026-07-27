import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/account_auth_repository.dart';
import 'package:paw_vault/core/auth/domain/services/account_deletion_service.dart';
import 'package:paw_vault/core/subscription/domain/entities/entitlements.dart';
import 'package:paw_vault/core/subscription/domain/entities/subscription_package.dart';
import 'package:paw_vault/core/subscription/domain/services/subscription_service.dart';
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

    test('identifies the user to the subscription service with their email',
        () async {
      final repository = _FakeAccountAuthRepository();
      final subscriptions = _FakeSubscriptionService();
      final cubit = AccountCubit(
        repository,
        subscriptionService: subscriptions,
      );

      repository.emitUser(
        const AppUser(
          id: 'u1',
          isAnonymous: false,
          email: 'a@b.com',
          displayName: 'Emma',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(subscriptions.identifiedUserId, 'u1');
      expect(subscriptions.identifiedEmail, 'a@b.com');
      expect(subscriptions.identifiedDisplayName, 'Emma');

      repository.emitUser(null);
      await Future<void>.delayed(Duration.zero);

      expect(subscriptions.resetCallCount, 1);

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
        states.any((s) => s.status == AccountStatus.authenticating),
        isTrue,
      );
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

    test('deleteAccount deletes then starts a fresh anonymous session',
        () async {
      final repository = _FakeAccountAuthRepository();
      final deletion = _FakeAccountDeletionService();
      final cubit = AccountCubit(repository, accountDeletionService: deletion);

      await cubit.deleteAccount();

      expect(deletion.deleteCallCount, 1);
      expect(repository.anonymousCallCount, 1);
      expect(cubit.state.status, AccountStatus.idle);
      expect(cubit.state.isSignedIn, isFalse);

      await cubit.close();
    });

    test('deleteAccount surfaces a friendly message on reauth required',
        () async {
      final repository = _FakeAccountAuthRepository();
      final deletion = _FakeAccountDeletionService(throwsReauth: true);
      final cubit = AccountCubit(repository, accountDeletionService: deletion);

      await cubit.deleteAccount();

      expect(cubit.state.status, AccountStatus.failure);
      expect(cubit.state.errorMessage, contains('sign in again'));
      expect(repository.anonymousCallCount, 0);

      await cubit.close();
    });
  });
}

class _FakeSubscriptionService implements SubscriptionService {
  String? identifiedUserId;
  String? identifiedEmail;
  String? identifiedDisplayName;
  int resetCallCount = 0;

  @override
  Future<void> identify(
    String userId, {
    String? email,
    String? displayName,
  }) async {
    identifiedUserId = userId;
    identifiedEmail = email;
    identifiedDisplayName = displayName;
  }

  @override
  Future<void> resetIdentity() async {
    resetCallCount++;
  }

  @override
  Stream<Entitlements> watchEntitlements() =>
      Stream<Entitlements>.value(Entitlements.free);

  @override
  Future<Entitlements> currentEntitlements() async => Entitlements.free;

  @override
  Future<List<SubscriptionPackage>> offerings() async => const [];

  @override
  Future<Entitlements> purchase(SubscriptionPackage package) async =>
      Entitlements.free;

  @override
  Future<Entitlements> restore() async => Entitlements.free;
}

class _FakeAccountDeletionService implements AccountDeletionService {
  _FakeAccountDeletionService({this.throwsReauth = false});

  final bool throwsReauth;
  int deleteCallCount = 0;

  @override
  Future<void> deleteAccount() async {
    deleteCallCount++;
    if (throwsReauth) {
      throw const ReauthenticationRequiredException();
    }
  }
}

class _FakeAccountAuthRepository implements AccountAuthRepository {
  _FakeAccountAuthRepository({this.throwsOnAuth = false});

  final bool throwsOnAuth;
  final _controller = StreamController<AppUser?>.broadcast();

  String? registeredEmail;
  int googleCallCount = 0;
  int signOutCallCount = 0;
  int anonymousCallCount = 0;

  void emitUser(AppUser? user) => _controller.add(user);

  AppUser _account({String? email}) =>
      AppUser(id: 'account-1', isAnonymous: false, email: email);

  @override
  Stream<AppUser?> watchCurrentUser() => _controller.stream;

  @override
  Future<AppUser?> currentUser() async => null;

  @override
  Future<AppUser> signInAnonymously() async {
    anonymousCallCount++;
    return const AppUser(id: 'anon', isAnonymous: true);
  }

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
