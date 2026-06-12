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
    return _requireUser(credential.user);
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
  }

  @override
  Stream<AppUser?> watchCurrentUser() {
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final credential =
        EmailAuthProvider.credential(email: email, password: password);
    return _linkOrSignIn(
      credential,
      createAccount: () => _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _requireUser(result.user);
  }

  @override
  Future<AppUser> signInWithGoogle() {
    throw UnimplementedError('Google sign-in is not configured yet.');
  }

  @override
  Future<AppUser> signInWithApple() {
    throw UnimplementedError('Apple sign-in is not configured yet.');
  }

  /// Links [credential] to the current anonymous user to preserve its data;
  /// falls back to [createAccount]/sign-in when there is no anonymous user or
  /// the credential already belongs to an account.
  Future<AppUser> _linkOrSignIn(
    AuthCredential credential, {
    required Future<UserCredential> Function() createAccount,
  }) async {
    final current = _auth.currentUser;

    try {
      if (current != null && current.isAnonymous) {
        final result = await current.linkWithCredential(credential);
        return _requireUser(result.user);
      }
      final result = await createAccount();
      return _requireUser(result.user);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use' ||
          error.code == 'credential-already-in-use') {
        final result = await _auth.signInWithCredential(credential);
        return _requireUser(result.user);
      }
      rethrow;
    }
  }

  AppUser _requireUser(User? user) {
    final mapped = _mapUser(user);
    if (mapped == null) {
      throw StateError('Firebase Auth did not return a user.');
    }
    return mapped;
  }

  AppUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }

    return AppUser(
      id: user.uid,
      isAnonymous: user.isAnonymous,
      email: user.email,
      displayName: user.displayName,
    );
  }
}
