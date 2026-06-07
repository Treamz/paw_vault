import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/presentation/models/pet_form_state.dart';

class PetProfileCubit extends Cubit<PetProfileState> {
  PetProfileCubit({
    required PetRepository petRepository,
    required AuthRepository authRepository,
  })  : _petRepository = petRepository,
        _authRepository = authRepository,
        super(const PetProfileState());

  final PetRepository _petRepository;
  final AuthRepository _authRepository;

  Future<void> load(String petId) async {
    emit(PetProfileState(status: PetProfileStatus.loading, petId: petId));

    try {
      await _petRepository.initialize();
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final userId = EntityId(user.id);
      final entityPetId = EntityId(petId);
      final pet = await _petRepository.getPet(
        userId: userId,
        petId: entityPetId,
      );

      emit(
        PetProfileState(
          status:
              pet == null ? PetProfileStatus.notFound : PetProfileStatus.ready,
          userId: userId,
          petId: petId,
          pet: pet,
        ),
      );
    } catch (error) {
      emit(
        PetProfileState(
          status: PetProfileStatus.failure,
          petId: petId,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> createPet(PetFormState formState) async {
    emit(state.copyWith(status: PetProfileStatus.saving));

    try {
      await _petRepository.initialize();
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final userId = EntityId(user.id);
      final now = DateTime.now();
      final petId = EntityId('${now.microsecondsSinceEpoch}');

      final pet = formState.toPet(
        id: petId,
        userId: userId,
        createdAt: now,
        updatedAt: now,
      );

      await _petRepository.savePet(pet);

      emit(
        PetProfileState(
          status: PetProfileStatus.ready,
          userId: userId,
          petId: petId.value,
          pet: pet,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PetProfileStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> updatePet(PetFormState formState) async {
    final currentPet = state.pet;
    if (currentPet == null) {
      emit(
        state.copyWith(
          status: PetProfileStatus.failure,
          errorMessage: 'Cannot update: no pet loaded',
        ),
      );
      return;
    }

    emit(state.copyWith(status: PetProfileStatus.saving));

    try {
      await _petRepository.initialize();
      final now = DateTime.now();

      final updatedPet = formState.toPet(
        id: currentPet.id,
        userId: currentPet.userId,
        createdAt: currentPet.createdAt?.value,
        updatedAt: now,
      );

      await _petRepository.savePet(updatedPet);

      emit(
        state.copyWith(
          status: PetProfileStatus.ready,
          pet: updatedPet,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PetProfileStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> deletePet() async {
    final currentPet = state.pet;
    if (currentPet == null) {
      emit(
        state.copyWith(
          status: PetProfileStatus.failure,
          errorMessage: 'Cannot delete: no pet loaded',
        ),
      );
      return;
    }

    emit(state.copyWith(status: PetProfileStatus.deleting));

    try {
      await _petRepository.initialize();
      await _petRepository.deletePet(
        userId: currentPet.userId,
        petId: currentPet.id,
      );

      emit(
        PetProfileState(
          status: PetProfileStatus.deleted,
          userId: currentPet.userId,
          petId: currentPet.id.value,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PetProfileStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}

enum PetProfileStatus {
  initial,
  loading,
  ready,
  saving,
  deleting,
  deleted,
  notFound,
  failure,
}

class PetProfileState {
  const PetProfileState({
    this.status = PetProfileStatus.initial,
    this.userId,
    this.petId,
    this.pet,
    this.errorMessage,
  });

  final PetProfileStatus status;
  final EntityId? userId;
  final String? petId;
  final Pet? pet;
  final String? errorMessage;

  bool get isReady => status == PetProfileStatus.ready;

  PetProfileState copyWith({
    PetProfileStatus? status,
    EntityId? userId,
    String? petId,
    Pet? pet,
    String? errorMessage,
  }) {
    return PetProfileState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      pet: pet ?? this.pet,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
