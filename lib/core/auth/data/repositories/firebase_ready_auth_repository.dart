import 'package:paw_vault/core/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/account_auth_repository.dart';

class FirebaseReadyAuthRepository implements AccountAuthRepository {
  const FirebaseReadyAuthRepository(this._dataSource);

  final FirebaseAuthDataSource _dataSource;

  @override
  Future<AppUser?> currentUser() => _dataSource.currentUser();

  @override
  Future<AppUser> signInAnonymously() => _dataSource.signInAnonymously();

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  Stream<AppUser?> watchCurrentUser() => _dataSource.watchCurrentUser();

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  }) =>
      _dataSource.registerWithEmail(email: email, password: password);

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _dataSource.signInWithEmail(email: email, password: password);

  @override
  Future<AppUser> signInWithGoogle() => _dataSource.signInWithGoogle();

  @override
  Future<AppUser> signInWithApple() => _dataSource.signInWithApple();
}
