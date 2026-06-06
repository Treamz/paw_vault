import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';

abstract interface class PetRepository {
  Future<void> initialize();

  Stream<List<Pet>> watchPets(EntityId userId);

  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  });

  Future<void> savePet(Pet pet);

  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  });
}
