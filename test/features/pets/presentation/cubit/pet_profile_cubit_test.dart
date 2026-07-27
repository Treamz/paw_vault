import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/pets/application/pet_photo_upload_service.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/services/pet_photo_picker.dart';
import 'package:paw_vault/features/pets/presentation/cubit/pet_profile_cubit.dart';
import 'package:paw_vault/features/pets/presentation/models/pet_form_state.dart';

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
        photoUploadService: PetPhotoUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
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
        photoUploadService: PetPhotoUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
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
        photoUploadService: PetPhotoUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
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
        photoUploadService: PetPhotoUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
      );

      await cubit.load('pet-1');

      expect(cubit.state.status, PetProfileStatus.failure);
      expect(cubit.state.petId, 'pet-1');
      expect(cubit.state.errorMessage, contains('initialize failed'));

      await cubit.close();
    });

    test('creates a new pet from form state', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final petRepository = _FakePetRepository();
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
        photoUploadService: PetPhotoUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
      );
      const formState = PetFormState(
        name: 'Fluffy',
        species: 'Cat',
        breed: 'Persian',
      );
      final states = <PetProfileState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.createPet(formState);
      await Future<void>.delayed(Duration.zero);

      expect(petRepository.initializeCallCount, 1);
      expect(petRepository.savePetCallCount, 1);
      expect(petRepository.savedPet, isNotNull);
      expect(petRepository.savedPet!.name, 'Fluffy');
      expect(petRepository.savedPet!.species, 'Cat');
      expect(petRepository.savedPet!.breed, 'Persian');
      expect(petRepository.savedPet!.userId, const EntityId('user-1'));
      expect(states.first.status, PetProfileStatus.saving);
      expect(states.last.status, PetProfileStatus.ready);
      expect(states.last.pet, petRepository.savedPet);
      expect(states.last.userId, const EntityId('user-1'));
      expect(states.last.petId, isNotEmpty);

      await subscription.cancel();
      await cubit.close();
    });

    test('creates pet with anonymous user when no current user', () async {
      final authRepository = _FakeAuthRepository(
        signedInUser: const AppUser(id: 'anon-1', isAnonymous: true),
      );
      final petRepository = _FakePetRepository();
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
        photoUploadService: PetPhotoUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
      );
      const formState = PetFormState(name: 'Buddy');

      await cubit.createPet(formState);

      expect(authRepository.signInAnonymouslyCallCount, 1);
      expect(petRepository.savedPet!.userId, const EntityId('anon-1'));
      expect(cubit.state.status, PetProfileStatus.ready);

      await cubit.close();
    });

    test('emits failure when create throws', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final petRepository = _FakePetRepository(throwsOnSave: true);
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
        photoUploadService: PetPhotoUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
      );
      const formState = PetFormState(name: 'Buddy');

      await cubit.createPet(formState);

      expect(cubit.state.status, PetProfileStatus.failure);
      expect(cubit.state.errorMessage, contains('save failed'));

      await cubit.close();
    });

    test('updates an existing pet from form state', () async {
      const existingPet = Pet(
        id: EntityId('pet-1'),
        userId: EntityId('user-1'),
        name: 'OldName',
        species: 'Dog',
      );
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final petRepository = _FakePetRepository(pet: existingPet);
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
        photoUploadService: PetPhotoUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
      );

      await cubit.load('pet-1');

      const formState = PetFormState(
        name: 'UpdatedName',
        species: 'Dog',
        breed: 'Labrador',
      );
      final states = <PetProfileState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.updatePet(formState);
      await Future<void>.delayed(Duration.zero);

      expect(petRepository.savePetCallCount, 1);
      expect(petRepository.savedPet, isNotNull);
      expect(petRepository.savedPet!.id, const EntityId('pet-1'));
      expect(petRepository.savedPet!.userId, const EntityId('user-1'));
      expect(petRepository.savedPet!.name, 'UpdatedName');
      expect(petRepository.savedPet!.breed, 'Labrador');
      expect(states.first.status, PetProfileStatus.saving);
      expect(states.last.status, PetProfileStatus.ready);
      expect(states.last.pet!.name, 'UpdatedName');

      await subscription.cancel();
      await cubit.close();
    });

    test('emits failure when updating with no loaded pet', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final petRepository = _FakePetRepository();
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
        photoUploadService: PetPhotoUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
      );
      const formState = PetFormState(name: 'UpdatedName');

      await cubit.updatePet(formState);

      expect(cubit.state.status, PetProfileStatus.failure);
      expect(
        cubit.state.errorMessage,
        contains('Cannot update: no pet loaded'),
      );
      expect(petRepository.savePetCallCount, isZero);

      await cubit.close();
    });

    test('emits failure when update throws', () async {
      const existingPet = Pet(
        id: EntityId('pet-1'),
        userId: EntityId('user-1'),
        name: 'OldName',
      );
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final petRepository = _FakePetRepository(
        pet: existingPet,
        throwsOnSave: true,
      );
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
        photoUploadService: PetPhotoUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
      );

      await cubit.load('pet-1');

      const formState = PetFormState(name: 'UpdatedName');

      await cubit.updatePet(formState);

      expect(cubit.state.status, PetProfileStatus.failure);
      expect(cubit.state.errorMessage, contains('save failed'));

      await cubit.close();
    });

    test('uploads a picked photo on create and stores its download URL',
        () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final petRepository = _FakePetRepository();
      final storageRepository = _FakeStorageRepository();
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
        photoUploadService: PetPhotoUploadService(
          storageRepository: storageRepository,
        ),
      );
      final formState = PetFormState(
        name: 'Fluffy',
        pickedPhoto: PickedPetPhoto(
          bytes: Uint8List.fromList([1, 2, 3]),
          contentType: 'image/jpeg',
        ),
      );

      await cubit.createPet(formState);

      final savedPet = petRepository.savedPet!;
      expect(storageRepository.uploadCallCount, 1);
      expect(storageRepository.uploadedContentType, 'image/jpeg');
      expect(
        storageRepository.uploadedPath,
        'users/user-1/pets/${savedPet.id.value}/photos/profile.jpg',
      );
      expect(
        savedPet.photoUrl,
        Uri.parse('https://cdn.example.com/${storageRepository.uploadedPath}'),
      );
      expect(cubit.state.status, PetProfileStatus.ready);

      await cubit.close();
    });

    test('does not upload a photo when none was picked', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final petRepository = _FakePetRepository();
      final storageRepository = _FakeStorageRepository();
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
        photoUploadService: PetPhotoUploadService(
          storageRepository: storageRepository,
        ),
      );

      await cubit.createPet(const PetFormState(name: 'Fluffy'));

      expect(storageRepository.uploadCallCount, isZero);
      expect(petRepository.savedPet!.photoUrl, isNull);

      await cubit.close();
    });

    test('uploads a picked photo on update and stores its download URL',
        () async {
      const existingPet = Pet(
        id: EntityId('pet-1'),
        userId: EntityId('user-1'),
        name: 'Fluffy',
      );
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final petRepository = _FakePetRepository(pet: existingPet);
      final storageRepository = _FakeStorageRepository();
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
        photoUploadService: PetPhotoUploadService(
          storageRepository: storageRepository,
        ),
      );

      await cubit.load('pet-1');

      final formState = PetFormState(
        name: 'Fluffy',
        pickedPhoto: PickedPetPhoto(
          bytes: Uint8List.fromList([4, 5, 6]),
          contentType: 'image/png',
        ),
      );

      await cubit.updatePet(formState);

      expect(storageRepository.uploadCallCount, 1);
      expect(
        storageRepository.uploadedPath,
        'users/user-1/pets/pet-1/photos/profile.jpg',
      );
      expect(
        petRepository.savedPet!.photoUrl,
        Uri.parse('https://cdn.example.com/${storageRepository.uploadedPath}'),
      );
      expect(cubit.state.status, PetProfileStatus.ready);

      await cubit.close();
    });

    test('deletes a loaded pet', () async {
      const existingPet = Pet(
        id: EntityId('pet-1'),
        userId: EntityId('user-1'),
        name: 'ToDelete',
      );
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final petRepository = _FakePetRepository(pet: existingPet);
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
        photoUploadService: PetPhotoUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
      );

      await cubit.load('pet-1');

      final states = <PetProfileState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.deletePet();
      await Future<void>.delayed(Duration.zero);

      expect(petRepository.deletePetCallCount, 1);
      expect(petRepository.deletedUserId, const EntityId('user-1'));
      expect(petRepository.deletedPetId, const EntityId('pet-1'));
      expect(states.first.status, PetProfileStatus.deleting);
      expect(states.last.status, PetProfileStatus.deleted);
      expect(states.last.userId, const EntityId('user-1'));
      expect(states.last.petId, 'pet-1');

      await subscription.cancel();
      await cubit.close();
    });

    test('emits failure when deleting with no loaded pet', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final petRepository = _FakePetRepository();
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
        photoUploadService: PetPhotoUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
      );

      await cubit.deletePet();

      expect(cubit.state.status, PetProfileStatus.failure);
      expect(
        cubit.state.errorMessage,
        contains('Cannot delete: no pet loaded'),
      );
      expect(petRepository.deletePetCallCount, isZero);

      await cubit.close();
    });

    test('emits failure when delete throws', () async {
      const existingPet = Pet(
        id: EntityId('pet-1'),
        userId: EntityId('user-1'),
        name: 'ToDelete',
      );
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final petRepository = _FakePetRepository(
        pet: existingPet,
        throwsOnDelete: true,
      );
      final cubit = PetProfileCubit(
        petRepository: petRepository,
        authRepository: authRepository,
        photoUploadService: PetPhotoUploadService(
          storageRepository: _FakeStorageRepository(),
        ),
      );

      await cubit.load('pet-1');

      await cubit.deletePet();

      expect(cubit.state.status, PetProfileStatus.failure);
      expect(cubit.state.errorMessage, contains('delete failed'));

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
    this.throwsOnSave = false,
    this.throwsOnDelete = false,
  });

  final Pet? pet;
  final bool throwsOnInitialize;
  final bool throwsOnSave;
  final bool throwsOnDelete;

  int initializeCallCount = 0;
  int savePetCallCount = 0;
  int deletePetCallCount = 0;
  EntityId? requestedUserId;
  EntityId? requestedPetId;
  Pet? savedPet;
  EntityId? deletedUserId;
  EntityId? deletedPetId;

  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) async {
    deletePetCallCount++;
    if (throwsOnDelete) {
      throw StateError('delete failed');
    }
    deletedUserId = userId;
    deletedPetId = petId;
  }

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
  Future<void> savePet(Pet pet) async {
    savePetCallCount++;
    if (throwsOnSave) {
      throw StateError('save failed');
    }
    savedPet = pet;
  }

  @override
  Stream<List<Pet>> watchPets(EntityId userId) {
    return Stream<List<Pet>>.value(const []);
  }
}

class _FakeStorageRepository implements StorageRepository {
  int uploadCallCount = 0;
  String? uploadedPath;
  Uint8List? uploadedBytes;
  String? uploadedContentType;

  @override
  Future<void> delete(String path) async {}

  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadCallCount++;
    uploadedPath = path;
    uploadedBytes = bytes;
    uploadedContentType = contentType;
    return StorageFile(
      path: path,
      downloadUrl: Uri.parse('https://cdn.example.com/$path'),
    );
  }
}
