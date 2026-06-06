import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';

class PetListCubit extends Cubit<PetListState> {
  PetListCubit(this._petRepository) : super(const PetListState());

  final PetRepository _petRepository;

  Future<void> load() async {
    await _petRepository.initialize();
    emit(const PetListState(isReady: true));
  }
}

class PetListState {
  const PetListState({this.isReady = false});

  final bool isReady;
}
