import 'package:paw_vault/features/pets/domain/entities/pet.dart';

abstract interface class FirestorePetDataSource {
  Stream<List<Pet>> watchPets(String userId);

  Future<Pet?> getPet({
    required String userId,
    required String petId,
  });

  Future<void> savePet(Pet pet);

  Future<void> deletePet({
    required String userId,
    required String petId,
  });
}
