import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/presentation/cubit/pet_list_cubit.dart';

void main() {
  group('PetListCubit', () {
    test('loads the current user and emits watched pets', () async {
      final pet = _pet();
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final petRepository = _FakePetRepository(watchedPets: [pet]);
      final cubit = PetListCubit(
        petRepository: petRepository,
        authRepository: authRepository,
      );
      final states = <PetListState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(petRepository.initializeCallCount, 1);
      expect(authRepository.currentUserCallCount, 1);
      expect(authRepository.signInAnonymouslyCallCount, isZero);
      expect(petRepository.watchedUserId, const EntityId('user-1'));
      expect(states.first.status, PetListStatus.loading);
      expect(states.last.status, PetListStatus.ready);
      expect(states.last.userId, const EntityId('user-1'));
      expect(states.last.pets, [pet]);

      await subscription.cancel();
      await cubit.close();
    });

    test('signs in anonymously when no current user exists', () async {
      final authRepository = _FakeAuthRepository(
        signedInUser: const AppUser(id: 'anonymous-user', isAnonymous: true),
      );
      final petRepository = _FakePetRepository();
      final cubit = PetListCubit(
        petRepository: petRepository,
        authRepository: authRepository,
      );

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(authRepository.currentUserCallCount, 1);
      expect(authRepository.signInAnonymouslyCallCount, 1);
      expect(petRepository.watchedUserId, const EntityId('anonymous-user'));
      expect(cubit.state.status, PetListStatus.ready);

      await cubit.close();
    });

    test('emits failure when loading throws', () async {
      final authRepository = _FakeAuthRepository();
      final petRepository = _FakePetRepository(throwsOnInitialize: true);
      final cubit = PetListCubit(
        petRepository: petRepository,
        authRepository: authRepository,
      );

      await cubit.load();

      expect(cubit.state.status, PetListStatus.failure);
      expect(cubit.state.errorMessage, contains('initialize failed'));

      await cubit.close();
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

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.currentUserValue,
    this.signedInUser = const AppUser(id: 'signed-in-user', isAnonymous: true),
  });

  final AppUser? currentUserValue;
  final AppUser signedInUser;

  int currentUserCallCount = 0;
  int signInAnonymouslyCallCount = 0;

  @override
  Future<AppUser?> currentUser() async {
    currentUserCallCount++;
    return currentUserValue;
  }

  @override
  Future<AppUser> signInAnonymously() async {
    signInAnonymouslyCallCount++;
    return signedInUser;
  }

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() {
    return Stream<AppUser?>.value(currentUserValue);
  }
}

class _FakePetRepository implements PetRepository {
  _FakePetRepository({
    this.watchedPets = const [],
    this.throwsOnInitialize = false,
  });

  final List<Pet> watchedPets;
  final bool throwsOnInitialize;

  int initializeCallCount = 0;
  EntityId? watchedUserId;

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
  Future<void> initialize() async {
    initializeCallCount++;
    if (throwsOnInitialize) {
      throw StateError('initialize failed');
    }
  }

  @override
  Future<void> savePet(Pet pet) async {}

  @override
  Stream<List<Pet>> watchPets(EntityId userId) {
    watchedUserId = userId;
    return Stream<List<Pet>>.value(watchedPets);
  }
}
