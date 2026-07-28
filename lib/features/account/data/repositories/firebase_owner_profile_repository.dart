import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';
import 'package:paw_vault/features/account/domain/entities/owner_profile.dart';
import 'package:paw_vault/features/account/domain/repositories/owner_profile_repository.dart';

/// [OwnerProfileRepository] backed by the user's Firestore document
/// (`users/{userId}`), which the security rules already scope to the owner.
class FirebaseOwnerProfileRepository implements OwnerProfileRepository {
  const FirebaseOwnerProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<OwnerProfile?> getOwnerProfile(EntityId userId) async {
    final snapshot =
        await _firestore.doc(FirestorePaths.user(userId.value)).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    final name = data['ownerName'];
    final phone = data['ownerPhone'];
    if (name is! String? || phone is! String?) {
      return null;
    }
    if (name == null && phone == null) {
      return null;
    }
    return OwnerProfile(name: name, phone: phone);
  }

  @override
  Future<void> saveOwnerProfile(EntityId userId, OwnerProfile profile) async {
    await _firestore.doc(FirestorePaths.user(userId.value)).set(
      {
        'ownerName': profile.name,
        'ownerPhone': profile.phone,
      },
      SetOptions(merge: true),
    );
  }
}
