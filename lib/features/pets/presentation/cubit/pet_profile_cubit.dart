import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';

class PetProfileCubit extends Cubit<PetProfileState> {
  PetProfileCubit(this._petRepository) : super(const PetProfileState());

  final PetRepository _petRepository;

  Future<void> load(String petId) async {
    await _petRepository.initialize();
    emit(PetProfileState(petId: petId, isReady: true));
  }
}

class PetProfileState {
  const PetProfileState({
    this.petId,
    this.isReady = false,
  });

  final String? petId;
  final bool isReady;
}
