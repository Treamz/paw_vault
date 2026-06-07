import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';

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
}

enum PetProfileStatus {
  initial,
  loading,
  ready,
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
}
