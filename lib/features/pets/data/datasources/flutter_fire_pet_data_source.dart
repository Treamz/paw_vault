import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';
import 'package:paw_vault/features/pets/data/datasources/firestore_pet_data_source.dart';
import 'package:paw_vault/features/pets/data/mappers/pet_firestore_mapper.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';

class FlutterFirePetDataSource implements FirestorePetDataSource {
  FlutterFirePetDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> deletePet({
    required String userId,
    required String petId,
  }) async {
    await _petDocument(userId: userId, petId: petId).delete();
  }

  @override
  Future<Pet?> getPet({
    required String userId,
    required String petId,
  }) async {
    final snapshot = await _petDocument(userId: userId, petId: petId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return PetFirestoreMapper.fromFirestore(
      id: EntityId(snapshot.id),
      data: data,
    );
  }

  @override
  Future<void> savePet(Pet pet) async {
    final document = _petDocument(
      userId: pet.userId.value,
      petId: pet.id.value,
    );
    final snapshot = await document.get();
    final data = PetFirestoreMapper.toFirestore(pet)
      ..remove('createdAt')
      ..remove('updatedAt')
      ..['updatedAt'] = FirestoreMapping.serverTimestamp();

    if (!snapshot.exists) {
      data['createdAt'] = FirestoreMapping.serverTimestamp();
    }

    await document.set(data, SetOptions(merge: true));
  }

  @override
  Stream<List<Pet>> watchPets(String userId) {
    return _firestore.collection(FirestorePaths.pets(userId)).snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (document) => PetFirestoreMapper.fromFirestore(
                  id: EntityId(document.id),
                  data: document.data(),
                ),
              )
              .toList(),
        );
  }

  DocumentReference<Map<String, Object?>> _petDocument({
    required String userId,
    required String petId,
  }) {
    return _firestore.doc(FirestorePaths.pet(userId: userId, petId: petId));
  }
}
