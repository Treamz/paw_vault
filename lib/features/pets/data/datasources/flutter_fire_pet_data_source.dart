import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';
import 'package:paw_vault/features/pets/data/datasources/firestore_pet_data_source.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';

class FlutterFirePetDataSource implements FirestorePetDataSource {
  FlutterFirePetDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<Pet?> getPet({
    required String userId,
    required String petId,
  }) async {
    await _firestore
        .doc(FirestorePaths.pet(userId: userId, petId: petId))
        .get();
    return null;
  }

  @override
  Stream<List<Pet>> watchPets(String userId) {
    return _firestore
        .collection(FirestorePaths.pets(userId))
        .snapshots()
        .map((_) => const <Pet>[]);
  }
}
