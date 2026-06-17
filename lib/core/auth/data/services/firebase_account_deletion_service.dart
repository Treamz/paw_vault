import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:paw_vault/core/auth/domain/services/account_deletion_service.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';

/// Deletes the signed-in user's data and Firebase Auth account.
///
/// Data is removed first, while the user is still authenticated (security rules
/// scope every document and file to the owner's uid); the auth account is
/// deleted last. All user data lives under `users/{uid}` in both Firestore and
/// Storage, so the whole tree is traversed and removed.
class FirebaseAccountDeletionService implements AccountDeletionService {
  const FirebaseAccountDeletionService(
    this._auth,
    this._firestore,
    this._storage,
  );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final uid = user.uid;

    await _deleteFirestoreData(uid);
    await _deleteStorageData(uid);

    try {
      await user.delete();
    } on FirebaseAuthException catch (error) {
      if (error.code == 'requires-recent-login') {
        throw const ReauthenticationRequiredException();
      }
      rethrow;
    }
  }

  Future<void> _deleteFirestoreData(String uid) async {
    final pets = await _firestore.collection(FirestorePaths.pets(uid)).get();
    for (final pet in pets.docs) {
      final petId = pet.id;
      final subcollections = [
        FirestorePaths.events(userId: uid, petId: petId),
        FirestorePaths.documents(userId: uid, petId: petId),
        FirestorePaths.reminders(userId: uid, petId: petId),
        FirestorePaths.smartMessages(userId: uid, petId: petId),
        FirestorePaths.vetSummaryExports(userId: uid, petId: petId),
      ];
      for (final path in subcollections) {
        await _deleteCollection(_firestore.collection(path));
      }
      await pet.reference.delete();
    }
    await _firestore.doc(FirestorePaths.user(uid)).delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    final snapshot = await ref.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _deleteStorageData(String uid) async {
    await _deleteStorageFolder(_storage.ref('users/$uid'));
  }

  Future<void> _deleteStorageFolder(Reference ref) async {
    final result = await ref.listAll();
    for (final item in result.items) {
      await item.delete();
    }
    for (final prefix in result.prefixes) {
      await _deleteStorageFolder(prefix);
    }
  }
}
