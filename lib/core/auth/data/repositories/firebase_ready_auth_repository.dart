import 'package:paw_vault/core/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';

class FirebaseReadyAuthRepository implements AuthRepository {
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
}
