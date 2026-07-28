import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/entities/weight_entry.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/weight_entry_repository.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';

class WeightHistoryCubit extends Cubit<WeightHistoryState> {
  WeightHistoryCubit({
    required WeightEntryRepository weightEntryRepository,
    required PetRepository petRepository,
    required AuthRepository authRepository,
  })  : _weightEntryRepository = weightEntryRepository,
        _petRepository = petRepository,
        _authRepository = authRepository,
        super(const WeightHistoryState());

  final WeightEntryRepository _weightEntryRepository;
  final PetRepository _petRepository;
  final AuthRepository _authRepository;
  StreamSubscription<List<WeightEntry>>? _subscription;

  Future<void> load(String petId) async {
    emit(WeightHistoryState(status: WeightHistoryStatus.loading, petId: petId));

    try {
      await _weightEntryRepository.initialize();
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final userId = EntityId(user.id);
      final entityPetId = EntityId(petId);
      final pet = await _petRepository.getPet(
        userId: userId,
        petId: entityPetId,
      );

      await _subscription?.cancel();
      _subscription = _weightEntryRepository
          .watchEntries(userId: userId, petId: entityPetId)
          .listen(
        (entries) {
          emit(
            WeightHistoryState(
              status: WeightHistoryStatus.ready,
              userId: userId,
              petId: petId,
              pet: state.pet ?? pet,
              entries: _sorted(entries),
            ),
          );
        },
        onError: (Object error) {
          emit(
            state.copyWith(
              status: WeightHistoryStatus.failure,
              errorMessage: error.toString(),
            ),
          );
        },
      );
    } catch (error) {
      emit(
        WeightHistoryState(
          status: WeightHistoryStatus.failure,
          petId: petId,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Adds a measurement; when it is the newest one it also becomes the pet's
  /// current weight.
  Future<void> addEntry({
    required double value,
    required PetWeightUnit unit,
    required DateOnly date,
  }) async {
    final userId = state.userId;
    final petId = state.petId;
    if (userId == null || petId == null) {
      return;
    }

    try {
      final now = DateTime.now();
      final entry = WeightEntry(
        id: EntityId('${now.microsecondsSinceEpoch}'),
        userId: userId,
        petId: EntityId(petId),
        value: value,
        unit: unit,
        date: date,
        createdAt: UtcDateTime(now),
      );
      await _weightEntryRepository.saveEntry(entry);

      final isNewest =
          state.entries.isEmpty || state.entries.last.date.compareTo(date) <= 0;
      if (isNewest) {
        await _updateCurrentWeight(entry);
      }
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<void> deleteEntry(WeightEntry entry) async {
    final userId = state.userId;
    final petId = state.petId;
    if (userId == null || petId == null) {
      return;
    }

    try {
      await _weightEntryRepository.deleteEntry(
        userId: userId,
        petId: EntityId(petId),
        entryId: entry.id,
      );
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<void> _updateCurrentWeight(WeightEntry entry) async {
    final pet = state.pet;
    if (pet == null) {
      return;
    }

    final updated = Pet(
      id: pet.id,
      userId: pet.userId,
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      birthDate: pet.birthDate,
      gender: pet.gender,
      weight: PetWeight(value: entry.value, unit: entry.unit),
      measurements: pet.measurements,
      microchipNumber: pet.microchipNumber,
      photoUrl: pet.photoUrl,
      allergies: pet.allergies,
      chronicConditions: pet.chronicConditions,
      notes: pet.notes,
      createdAt: pet.createdAt,
      updatedAt: pet.updatedAt,
    );
    await _petRepository.savePet(updated);
    emit(state.copyWith(pet: updated));
  }

  static List<WeightEntry> _sorted(List<WeightEntry> entries) {
    final sorted = [...entries];
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

enum WeightHistoryStatus {
  initial,
  loading,
  ready,
  failure,
}

class WeightHistoryState {
  const WeightHistoryState({
    this.status = WeightHistoryStatus.initial,
    this.userId,
    this.petId,
    this.pet,
    this.entries = const [],
    this.errorMessage,
  });

  final WeightHistoryStatus status;
  final EntityId? userId;
  final String? petId;
  final Pet? pet;

  /// Entries sorted by date, oldest first (chart order).
  final List<WeightEntry> entries;
  final String? errorMessage;

  /// The unit measurements are displayed in: the pet's current unit, falling
  /// back to the latest entry's unit.
  PetWeightUnit get displayUnit =>
      pet?.weight?.unit ??
      (entries.isEmpty ? PetWeightUnit.kilogram : entries.last.unit);

  WeightHistoryState copyWith({
    WeightHistoryStatus? status,
    EntityId? userId,
    String? petId,
    Pet? pet,
    List<WeightEntry>? entries,
    String? errorMessage,
  }) {
    return WeightHistoryState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      pet: pet ?? this.pet,
      entries: entries ?? this.entries,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
