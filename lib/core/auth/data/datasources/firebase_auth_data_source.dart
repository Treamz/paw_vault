import 'package:paw_vault/core/auth/domain/entities/app_user.dart';

abstract interface class FirebaseAuthDataSource {
  Stream<AppUser?> watchCurrentUser();

  Future<AppUser?> currentUser();

  Future<AppUser> signInAnonymously();

  Future<void> signOut();

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
