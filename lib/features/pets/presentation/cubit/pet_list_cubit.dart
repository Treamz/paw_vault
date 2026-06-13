import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';

class PetListCubit extends Cubit<PetListState> {
  PetListCubit({
    required PetRepository petRepository,
    required AuthRepository authRepository,
  })  : _petRepository = petRepository,
        _authRepository = authRepository,
        super(const PetListState());

  final PetRepository _petRepository;
  final AuthRepository _authRepository;
  StreamSubscription<List<Pet>>? _petsSubscription;
  StreamSubscription<AppUser?>? _authSubscription;
  EntityId? _userId;

  Future<void> load() async {
    emit(const PetListState(status: PetListStatus.loading));

    try {
      await _petRepository.initialize();
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      _watchPetsFor(EntityId(user.id));

      // React to later auth changes (e.g. sign-out switching to a fresh
      // anonymous session) by re-subscribing to the new user's pets.
      await _authSubscription?.cancel();
      _authSubscription =
          _authRepository.watchCurrentUser().listen(_onUserChanged);
    } catch (error) {
      emit(
        PetListState(
          status: PetListStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onUserChanged(AppUser? user) {
    // A null user is transient during sign-out; a fresh session follows.
    if (user == null) return;
    final userId = EntityId(user.id);
    if (userId == _userId) return;
    _watchPetsFor(userId);
  }

  void _watchPetsFor(EntityId userId) {
    _userId = userId;
    _petsSubscription?.cancel();
    _petsSubscription = _petRepository.watchPets(userId).listen(
      (pets) {
        emit(
          PetListState(
            status: PetListStatus.ready,
            userId: userId,
            pets: pets,
          ),
        );
      },
      onError: (Object error) {
        emit(
          PetListState(
            status: PetListStatus.failure,
            userId: userId,
            errorMessage: error.toString(),
          ),
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    await _petsSubscription?.cancel();
    return super.close();
  }
}

enum PetListStatus {
  initial,
  loading,
  ready,
  failure,
}

class PetListState {
  const PetListState({
    this.status = PetListStatus.initial,
    this.userId,
    this.pets = const [],
    this.errorMessage,
  });

  final PetListStatus status;
  final EntityId? userId;
  final List<Pet> pets;
  final String? errorMessage;

  bool get isReady => status == PetListStatus.ready;
}
