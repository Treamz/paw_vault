import 'package:paw_vault/core/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';

class NoopFirebaseAuthDataSource implements FirebaseAuthDataSource {
  static const _anonymousUser = AppUser(
    id: 'local-anonymous-user',
    isAnonymous: true,
  );

  @override
  Future<AppUser?> currentUser() async => _anonymousUser;

  @override
  Future<AppUser> signInAnonymously() async => _anonymousUser;

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() {
    return Stream<AppUser?>.value(_anonymousUser);
  }

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    return AppUser(id: 'local-account', isAnonymous: false, email: email);
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return AppUser(id: 'local-account', isAnonymous: false, email: email);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    return const AppUser(id: 'local-account', isAnonymous: false);
  }

  @override
  Future<AppUser> signInWithApple() async {
    return const AppUser(id: 'local-account', isAnonymous: false);
  }
}
