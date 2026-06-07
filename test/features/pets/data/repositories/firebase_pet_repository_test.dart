import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/data/datasources/firestore_pet_data_source.dart';
import 'package:paw_vault/features/pets/data/repositories/firebase_pet_repository.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';

void main() {
  group('FirebasePetRepository', () {
    test('watches pets through the Firestore data source', () async {
      final pet = _pet();
      final dataSource = _FakeFirestorePetDataSource(watchedPets: [pet]);
      final repository = FirebasePetRepository(dataSource);

      final pets = await repository.watchPets(const EntityId('user-1')).first;

      expect(pets, [pet]);
      expect(dataSource.watchedUserId, 'user-1');
    });

    test('gets a pet through the Firestore data source', () async {
      final pet = _pet();
      final dataSource = _FakeFirestorePetDataSource(foundPet: pet);
      final repository = FirebasePetRepository(dataSource);

      final result = await repository.getPet(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
      );

      expect(result, pet);
      expect(dataSource.getUserId, 'user-1');
      expect(dataSource.getPetId, 'pet-1');
    });

    test('saves a pet through the Firestore data source', () async {
      final pet = _pet();
      final dataSource = _FakeFirestorePetDataSource();
      final repository = FirebasePetRepository(dataSource);

      await repository.savePet(pet);

      expect(dataSource.savedPet, pet);
    });

    test('deletes a pet through the Firestore data source', () async {
      final dataSource = _FakeFirestorePetDataSource();
      final repository = FirebasePetRepository(dataSource);

      await repository.deletePet(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
      );

      expect(dataSource.deletedUserId, 'user-1');
      expect(dataSource.deletedPetId, 'pet-1');
    });
  });
}

Pet _pet() {
  return const Pet(
    id: EntityId('pet-1'),
    userId: EntityId('user-1'),
    name: 'Mochi',
  );
}

class _FakeFirestorePetDataSource implements FirestorePetDataSource {
  _FakeFirestorePetDataSource({
    this.watchedPets = const [],
    this.foundPet,
  });

  final List<Pet> watchedPets;
  final Pet? foundPet;

  String? watchedUserId;
  String? getUserId;
  String? getPetId;
  Pet? savedPet;
  String? deletedUserId;
  String? deletedPetId;

  @override
  Future<void> deletePet({
    required String userId,
    required String petId,
  }) async {
    deletedUserId = userId;
    deletedPetId = petId;
  }

  @override
  Future<Pet?> getPet({
    required String userId,
    required String petId,
  }) async {
    getUserId = userId;
    getPetId = petId;
    return foundPet;
  }

  @override
  Future<void> savePet(Pet pet) async {
    savedPet = pet;
  }

  @override
  Stream<List<Pet>> watchPets(String userId) {
    watchedUserId = userId;
    return Stream<List<Pet>>.value(watchedPets);
  }
}
