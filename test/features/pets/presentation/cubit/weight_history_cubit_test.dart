import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/data/repositories/local_weight_entry_repository.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/entities/weight_entry.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';
import 'package:paw_vault/features/pets/presentation/cubit/weight_history_cubit.dart';

void main() {
  group('WeightHistoryCubit', () {
    WeightHistoryCubit cubit({
      LocalWeightEntryRepository? entries,
      _FakePetRepository? pets,
    }) {
      return WeightHistoryCubit(
        weightEntryRepository: entries ?? LocalWeightEntryRepository(),
        petRepository: pets ?? _FakePetRepository(pet: _pet()),
        authRepository: _FakeAuthRepository(),
      );
    }

    test('loads entries sorted by date ascending', () async {
      final repository = LocalWeightEntryRepository();
      await repository.saveEntry(_entry(id: 'b', day: 20, value: 6));
      await repository.saveEntry(_entry(id: 'a', day: 5, value: 5));
      final sut = cubit(entries: repository);

      await sut.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(sut.state.status, WeightHistoryStatus.ready);
      expect(sut.state.entries.map((e) => e.id.value), ['a', 'b']);

      await sut.close();
    });

    test('adding the newest entry updates the pet current weight', () async {
      final repository = LocalWeightEntryRepository();
      final pets = _FakePetRepository(pet: _pet());
      final sut = cubit(entries: repository, pets: pets);

      await sut.load('pet-1');
      await Future<void>.delayed(Duration.zero);
      await sut.addEntry(
        value: 7.2,
        unit: PetWeightUnit.kilogram,
        date: DateOnly.fromDateTime(DateTime.now()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(sut.state.entries, hasLength(1));
      expect(pets.savedPet?.weight?.value, 7.2);

      await sut.close();
    });

    test('adding an older entry keeps the current weight untouched', () async {
      final repository = LocalWeightEntryRepository();
      await repository
          .saveEntry(_entry(id: 'latest', day: 25, value: 6, month: 7));
      final pets = _FakePetRepository(pet: _pet());
      final sut = cubit(entries: repository, pets: pets);

      await sut.load('pet-1');
      await Future<void>.delayed(Duration.zero);
      await sut.addEntry(
        value: 4.5,
        unit: PetWeightUnit.kilogram,
        date: const DateOnly(year: 2025, month: 1, day: 1),
      );
      await Future<void>.delayed(Duration.zero);

      expect(sut.state.entries, hasLength(2));
      expect(pets.savedPet, isNull);

      await sut.close();
    });

    test('deleteEntry removes the entry from the stream', () async {
      final repository = LocalWeightEntryRepository();
      final entry = _entry(id: 'gone', day: 10, value: 5);
      await repository.saveEntry(entry);
      final sut = cubit(entries: repository);

      await sut.load('pet-1');
      await Future<void>.delayed(Duration.zero);
      await sut.deleteEntry(entry);
      await Future<void>.delayed(Duration.zero);

      expect(sut.state.entries, isEmpty);

      await sut.close();
    });
  });
}

Pet _pet() {
  return const Pet(
    id: EntityId('pet-1'),
    userId: EntityId('user-1'),
    name: 'Rex',
    weight: PetWeight(value: 5),
  );
}

WeightEntry _entry({
  required String id,
  required int day,
  required double value,
  int month = 6,
}) {
  return WeightEntry(
    id: EntityId(id),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    value: value,
    date: DateOnly(year: 2026, month: month, day: day),
  );
}

class _FakeAuthRepository implements AuthRepository {
  static const _user = AppUser(id: 'user-1', isAnonymous: true);

  @override
  Future<AppUser?> currentUser() async => _user;

  @override
  Future<AppUser> signInAnonymously() async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() => Stream<AppUser?>.value(_user);
}

class _FakePetRepository implements PetRepository {
  _FakePetRepository({this.pet});

  final Pet? pet;
  Pet? savedPet;

  @override
  Future<void> initialize() async {}

  @override
  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  }) async =>
      pet;

  @override
  Future<void> savePet(Pet pet) async {
    savedPet = pet;
  }

  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) async {}

  @override
  Stream<List<Pet>> watchPets(EntityId userId) =>
      Stream<List<Pet>>.value([if (pet != null) pet!]);
}
