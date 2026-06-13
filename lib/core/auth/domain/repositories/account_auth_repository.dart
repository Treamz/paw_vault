import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';

/// Extends [AuthRepository] with account (non-anonymous) authentication.
///
/// Sign-up/sign-in methods link the new credential to the current anonymous
/// user where possible, so existing records carry over; when the credential
/// already belongs to an account they fall back to signing in.
abstract interface class AccountAuthRepository implements AuthRepository {
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInWithApple();
}
