import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_events.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/data/services/noop_account_deletion_service.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/account_auth_repository.dart';
import 'package:paw_vault/core/auth/domain/services/account_deletion_service.dart';
import 'package:paw_vault/core/subscription/data/services/noop_subscription_service.dart';
import 'package:paw_vault/core/subscription/domain/services/subscription_service.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit(
    this._repository, {
    AnalyticsService? analytics,
    SubscriptionService? subscriptionService,
    AccountDeletionService? accountDeletionService,
  })  : _analytics = analytics ?? const NoopAnalyticsService(),
        _subscriptionService =
            subscriptionService ?? const NoopSubscriptionService(),
        _accountDeletionService =
            accountDeletionService ?? const NoopAccountDeletionService(),
        super(const AccountState()) {
    _subscription = _repository.watchCurrentUser().listen((user) {
      // Tie analytics + subscriptions to the current (possibly anonymous) uid.
      _analytics.setUserId(user?.id);
      if (user != null) {
        _subscriptionService.identify(
          user.id,
          email: user.email,
          displayName: user.displayName,
        );
      } else {
        _subscriptionService.resetIdentity();
      }
      emit(state.copyWith(user: user, clearUser: user == null));
    });
  }

  final AccountAuthRepository _repository;
  final AnalyticsService _analytics;
  final SubscriptionService _subscriptionService;
  final AccountDeletionService _accountDeletionService;
  StreamSubscription<AppUser?>? _subscription;

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) =>
      _run(
        () => _repository.registerWithEmail(
          email: email,
          password: password,
        ),
        method: 'email',
      );

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _run(
        () => _repository.signInWithEmail(
          email: email,
          password: password,
        ),
        method: 'email',
      );

  Future<void> signInWithGoogle() =>
      _run(_repository.signInWithGoogle, method: 'google');

  Future<void> signInWithApple() =>
      _run(_repository.signInWithApple, method: 'apple');

  Future<void> signOut() async {
    try {
      await _repository.signOut();
      // Re-establish a fresh anonymous session so the app keeps working and
      // the previous account's data is no longer shown.
      await _repository.signInAnonymously();
    } catch (error) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Permanently deletes the signed-in account and its data, then starts a
  /// fresh anonymous session so the app keeps working.
  Future<void> deleteAccount() async {
    emit(
      state.copyWith(status: AccountStatus.authenticating, clearError: true),
    );
    try {
      await _accountDeletionService.deleteAccount();
      await _repository.signInAnonymously();
      emit(state.copyWith(status: AccountStatus.idle, clearUser: true));
    } on ReauthenticationRequiredException {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: 'For your security, please sign in again, then delete '
              'your account.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _run(
    Future<AppUser> Function() action, {
    required String method,
  }) async {
    emit(
      state.copyWith(status: AccountStatus.authenticating, clearError: true),
    );
    try {
      final user = await action();
      _analytics.logEvent(
        AnalyticsEvents.login,
        parameters: {AnalyticsParams.method: method},
      );
      emit(state.copyWith(status: AccountStatus.idle, user: user));
    } catch (error) {
      emit(
        state.copyWith(
          status: AccountStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

enum AccountStatus {
  idle,
  authenticating,
  failure,
}

class AccountState {
  const AccountState({
    this.status = AccountStatus.idle,
    this.user,
    this.errorMessage,
  });

  final AccountStatus status;
  final AppUser? user;
  final String? errorMessage;

  bool get isAuthenticating => status == AccountStatus.authenticating;
  bool get isSignedIn => user != null && !user!.isAnonymous;

  AccountState copyWith({
    AccountStatus? status,
    AppUser? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AccountState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
