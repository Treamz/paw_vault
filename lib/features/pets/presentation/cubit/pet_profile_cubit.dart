import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_events.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/account/domain/entities/owner_profile.dart';
import 'package:paw_vault/features/account/domain/repositories/owner_profile_repository.dart';
import 'package:paw_vault/features/pets/application/pet_photo_upload_service.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/entities/weight_entry.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';
import 'package:paw_vault/features/pets/domain/repositories/weight_entry_repository.dart';
import 'package:paw_vault/features/pets/presentation/models/pet_form_state.dart';

class PetProfileCubit extends Cubit<PetProfileState> {
  PetProfileCubit({
    required PetRepository petRepository,
    required AuthRepository authRepository,
    required PetPhotoUploadService photoUploadService,
    OwnerProfileRepository? ownerProfileRepository,
    WeightEntryRepository? weightEntryRepository,
    AnalyticsService? analytics,
  })  : _petRepository = petRepository,
        _authRepository = authRepository,
        _photoUploadService = photoUploadService,
        _ownerProfileRepository = ownerProfileRepository,
        _weightEntryRepository = weightEntryRepository,
        _analytics = analytics ?? const NoopAnalyticsService(),
        super(const PetProfileState());

  final PetRepository _petRepository;
  final AuthRepository _authRepository;
  final PetPhotoUploadService _photoUploadService;
  final OwnerProfileRepository? _ownerProfileRepository;
  final WeightEntryRepository? _weightEntryRepository;
  final AnalyticsService _analytics;

  /// Appends a weight-history entry when the pet's weight was set or changed
  /// through the form, so the graph builds itself.
  Future<void> _logWeightChange({
    required Pet saved,
    Pet? previous,
    required DateTime now,
  }) async {
    final repository = _weightEntryRepository;
    final weight = saved.weight;
    if (repository == null || weight == null) {
      return;
    }
    final unchanged = previous?.weight != null &&
        previous!.weight!.value == weight.value &&
        previous.weight!.unit == weight.unit;
    if (unchanged) {
      return;
    }

    await repository.saveEntry(
      WeightEntry(
        id: EntityId('${now.microsecondsSinceEpoch}-weight'),
        userId: saved.userId,
        petId: saved.id,
        value: weight.value,
        unit: weight.unit,
        date: DateOnly.fromDateTime(now),
        createdAt: UtcDateTime(now),
      ),
    );
  }

  /// Saves the owner's contact details and reflects them in the state.
  Future<void> saveOwnerInfo({String? name, String? phone}) async {
    final repository = _ownerProfileRepository;
    final userId = state.userId;
    if (repository == null || userId == null) {
      return;
    }

    String? clean(String? value) {
      final trimmed = value?.trim();
      return trimmed == null || trimmed.isEmpty ? null : trimmed;
    }

    final profile = OwnerProfile(name: clean(name), phone: clean(phone));
    try {
      await repository.saveOwnerProfile(userId, profile);
      emit(state.copyWith(ownerProfile: profile));
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  /// Uploads the form's freshly picked photo (if any) and returns the form
  /// state with [PetFormState.photoUrl] pointing at the uploaded file.
  Future<PetFormState> _withUploadedPhoto({
    required PetFormState formState,
    required EntityId userId,
    required EntityId petId,
  }) async {
    final photo = formState.pickedPhoto;
    if (photo == null) {
      return formState;
    }

    final uploaded = await _photoUploadService.uploadProfilePhoto(
      userId: userId,
      petId: petId,
      photo: photo,
    );

    return formState.copyWith(photoUrl: uploaded.downloadUrl.toString());
  }

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
      OwnerProfile? ownerProfile;
      try {
        ownerProfile = await _ownerProfileRepository?.getOwnerProfile(userId);
      } catch (_) {
        // Owner details are auxiliary; the profile still renders without.
      }

      emit(
        PetProfileState(
          status:
              pet == null ? PetProfileStatus.notFound : PetProfileStatus.ready,
          userId: userId,
          petId: petId,
          pet: pet,
          owner: user,
          ownerProfile: ownerProfile,
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

      final formWithPhoto = await _withUploadedPhoto(
        formState: formState,
        userId: userId,
        petId: petId,
      );

      final pet = formWithPhoto.toPet(
        id: petId,
        userId: userId,
        createdAt: now,
        updatedAt: now,
      );

      await _petRepository.savePet(pet);
      await _logWeightChange(saved: pet, now: now);
      _analytics.logEvent(AnalyticsEvents.petCreated);

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

      final formWithPhoto = await _withUploadedPhoto(
        formState: formState,
        userId: currentPet.userId,
        petId: currentPet.id,
      );

      final updatedPet = formWithPhoto.toPet(
        id: currentPet.id,
        userId: currentPet.userId,
        createdAt: currentPet.createdAt?.value,
        updatedAt: now,
      );

      await _petRepository.savePet(updatedPet);
      await _logWeightChange(
        saved: updatedPet,
        previous: currentPet,
        now: now,
      );

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
    this.owner,
    this.ownerProfile,
    this.errorMessage,
  });

  final PetProfileStatus status;
  final EntityId? userId;
  final String? petId;
  final Pet? pet;

  /// The signed-in account that owns this pet; anonymous sessions have no
  /// owner details to show.
  final AppUser? owner;

  /// User-entered owner contact details (name/phone).
  final OwnerProfile? ownerProfile;
  final String? errorMessage;

  bool get isReady => status == PetProfileStatus.ready;

  PetProfileState copyWith({
    PetProfileStatus? status,
    EntityId? userId,
    String? petId,
    Pet? pet,
    AppUser? owner,
    OwnerProfile? ownerProfile,
    String? errorMessage,
  }) {
    return PetProfileState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      pet: pet ?? this.pet,
      owner: owner ?? this.owner,
      ownerProfile: ownerProfile ?? this.ownerProfile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
