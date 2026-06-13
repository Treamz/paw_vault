import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/account_auth_repository.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._repository) : super(const AccountState()) {
    _subscription = _repository.watchCurrentUser().listen((user) {
      emit(state.copyWith(user: user, clearUser: user == null));
    });
  }

  final AccountAuthRepository _repository;
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
      );

  Future<void> signInWithGoogle() => _run(_repository.signInWithGoogle);

  Future<void> signInWithApple() => _run(_repository.signInWithApple);

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

  Future<void> _run(Future<AppUser> Function() action) async {
    emit(
      state.copyWith(status: AccountStatus.authenticating, clearError: true),
    );
    try {
      final user = await action();
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
