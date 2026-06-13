import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:paw_vault/core/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FlutterFireAuthDataSource implements FirebaseAuthDataSource {
  FlutterFireAuthDataSource(this._auth, {GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;

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
    // userChanges (not authStateChanges) so the UI also reacts when an
    // anonymous account is linked to a credential — the uid is unchanged, so
    // authStateChanges would not fire and the account would still look
    // anonymous.
    return _auth.userChanges().map(_mapUser);
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
  Future<AppUser> signInWithGoogle() async {
    if (!_googleInitialized) {
      await _googleSignIn.initialize();
      _googleInitialized = true;
    }

    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google sign-in did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _linkOrSignIn(
      credential,
      createAccount: () => _auth.signInWithCredential(credential),
    );
  }

  @override
  Future<AppUser> signInWithApple() async {
    final rawNonce = _generateNonce();
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: _sha256(rawNonce),
    );

    final idToken = appleCredential.identityToken;
    if (idToken == null) {
      throw StateError('Apple sign-in did not return an identity token.');
    }

    final credential = OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
    );
    return _linkOrSignIn(
      credential,
      createAccount: () => _auth.signInWithCredential(credential),
    );
  }

  /// A random nonce; its SHA-256 hash is sent to Apple and the raw value to
  /// Firebase, to protect against replay attacks.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256(String input) => sha256.convert(utf8.encode(input)).toString();

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
