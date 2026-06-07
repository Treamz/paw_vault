import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/presentation/cubit/pet_profile_cubit.dart';

void main() {
  group('PetProfileCubit', () {
    test('loads the current user and fetches the requested pet', () async {
      final pet = _pet();
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final petRepository = _FakePetRepository(pet: pet);
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
      );
      final states = <PetProfileState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(petRepository.initializeCallCount, 1);
      expect(authRepository.currentUserCallCount, 1);
      expect(authRepository.signInAnonymouslyCallCount, isZero);
      expect(petRepository.requestedUserId, const EntityId('user-1'));
      expect(petRepository.requestedPetId, const EntityId('pet-1'));
      expect(states.first.status, PetProfileStatus.loading);
      expect(states.last.status, PetProfileStatus.ready);
      expect(states.last.userId, const EntityId('user-1'));
      expect(states.last.petId, 'pet-1');
      expect(states.last.pet, pet);
      expect(states.last.isReady, isTrue);

      await subscription.cancel();
      await cubit.close();
    });

    test('signs in anonymously when no current user exists', () async {
      final pet = _pet(userId: const EntityId('anonymous-user'));
      final authRepository = _FakeAuthRepository(
        signedInUser: const AppUser(id: 'anonymous-user', isAnonymous: true),
      );
      final petRepository = _FakePetRepository(pet: pet);
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1');

      expect(authRepository.currentUserCallCount, 1);
      expect(authRepository.signInAnonymouslyCallCount, 1);
      expect(petRepository.requestedUserId, const EntityId('anonymous-user'));
      expect(cubit.state.status, PetProfileStatus.ready);

      await cubit.close();
    });

    test('emits notFound when repository returns no pet', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final petRepository = _FakePetRepository();
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
      );

      await cubit.load('missing-pet');

      expect(cubit.state.status, PetProfileStatus.notFound);
      expect(cubit.state.userId, const EntityId('user-1'));
      expect(cubit.state.petId, 'missing-pet');
      expect(cubit.state.pet, isNull);
      expect(cubit.state.isReady, isFalse);

      await cubit.close();
    });

    test('emits failure when loading throws', () async {
      final authRepository = _FakeAuthRepository();
      final petRepository = _FakePetRepository(throwsOnInitialize: true);
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1');

      expect(cubit.state.status, PetProfileStatus.failure);
      expect(cubit.state.petId, 'pet-1');
      expect(cubit.state.errorMessage, contains('initialize failed'));

      await cubit.close();
    });
  });
}

Pet _pet({
  EntityId userId = const EntityId('user-1'),
}) {
  return Pet(
    id: const EntityId('pet-1'),
    userId: userId,
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
    this.pet,
    this.throwsOnInitialize = false,
  });

  final Pet? pet;
  final bool throwsOnInitialize;

  int initializeCallCount = 0;
  EntityId? requestedUserId;
  EntityId? requestedPetId;

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
    requestedUserId = userId;
    requestedPetId = petId;
    return pet;
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
    return Stream<List<Pet>>.value(const []);
  }
}
