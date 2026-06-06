import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';

class LocalPetRepository implements PetRepository {
  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) async {}

  @override
  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  }) async {
    return null;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> savePet(Pet pet) async {}

  @override
  Stream<List<Pet>> watchPets(EntityId userId) {
    return Stream<List<Pet>>.value(const []);
  }
}
