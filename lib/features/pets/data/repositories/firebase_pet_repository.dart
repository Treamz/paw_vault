import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/data/datasources/firestore_pet_data_source.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';

class FirebasePetRepository implements PetRepository {
  const FirebasePetRepository(this._dataSource);

  final FirestorePetDataSource _dataSource;

  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) {
    return _dataSource.deletePet(
      userId: userId.value,
      petId: petId.value,
    );
  }

  @override
  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  }) {
    return _dataSource.getPet(
      userId: userId.value,
      petId: petId.value,
    );
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> savePet(Pet pet) {
    return _dataSource.savePet(pet);
  }

  @override
  Stream<List<Pet>> watchPets(EntityId userId) {
    return _dataSource.watchPets(userId.value);
  }
}
