import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';
import 'package:paw_vault/features/pets/data/mappers/weight_entry_firestore_mapper.dart';
import 'package:paw_vault/features/pets/domain/entities/weight_entry.dart';
import 'package:paw_vault/features/pets/domain/repositories/weight_entry_repository.dart';

/// [WeightEntryRepository] backed by the
/// `users/{userId}/pets/{petId}/weightEntries` Firestore subcollection,
/// already covered by the owner-scoped security rules.
class FirebaseWeightEntryRepository implements WeightEntryRepository {
  const FirebaseWeightEntryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection({
    required String userId,
    required String petId,
  }) {
    return _firestore.collection(
      FirestorePaths.weightEntries(userId: userId, petId: petId),
    );
  }

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<WeightEntry>> watchEntries({
    required EntityId userId,
    required EntityId petId,
  }) {
    return _collection(userId: userId.value, petId: petId.value)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              WeightEntryFirestoreMapper.fromFirestore(
                id: EntityId(doc.id),
                data: doc.data(),
              ),
          ],
        );
  }

  @override
  Future<void> saveEntry(WeightEntry entry) async {
    final data = WeightEntryFirestoreMapper.toFirestore(entry)
      ..remove('createdAt')
      ..['createdAt'] = FirestoreMapping.serverTimestamp();
    await _collection(userId: entry.userId.value, petId: entry.petId.value)
        .doc(entry.id.value)
        .set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteEntry({
    required EntityId userId,
    required EntityId petId,
    required EntityId entryId,
  }) async {
    await _collection(userId: userId.value, petId: petId.value)
        .doc(entryId.value)
        .delete();
  }
}
