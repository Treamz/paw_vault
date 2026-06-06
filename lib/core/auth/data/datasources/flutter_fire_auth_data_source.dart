import 'package:firebase_auth/firebase_auth.dart';
import 'package:paw_vault/core/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';

class FlutterFireAuthDataSource implements FirebaseAuthDataSource {
  FlutterFireAuthDataSource(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<AppUser?> currentUser() async {
    return _mapUser(_auth.currentUser);
  }

  @override
  Future<AppUser> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    final user = _mapUser(credential.user);
    if (user == null) {
      throw StateError('Firebase Auth did not return a user.');
    }
    return user;
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
  }

  @override
  Stream<AppUser?> watchCurrentUser() {
    return _auth.authStateChanges().map(_mapUser);
  }

  AppUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }

    return AppUser(
      id: user.uid,
      isAnonymous: user.isAnonymous,
    );
  }
}
