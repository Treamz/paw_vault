import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_events.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/paw_scan/application/paw_photo_upload_service.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_photo.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_scan_draft.dart';
import 'package:paw_vault/features/paw_scan/domain/repositories/paw_check_repository.dart';
import 'package:paw_vault/features/paw_scan/domain/repositories/paw_scan_ai_repository.dart';
import 'package:paw_vault/features/paw_scan/domain/services/paw_photo_picker.dart';

/// The most photos one scan may carry — one per paw.
const kMaxPawScanPhotos = 4;

enum PawScanStatus {
  idle,
  capturing,
  analyzing,

  /// A result is on screen for the owner to review.
  review,

  /// The photos could not be used, or the model refused. No verdict is shown.
  rejected,

  saving,
  saved,
  failure,
}

enum PawJournalStatus { loading, ready, failure }

class PawScanState {
  const PawScanState({
    this.status = PawScanStatus.idle,
    this.photos = const [],
    this.draft,
    this.location = PawLocation.unspecified,
    this.errorMessage,
    this.journalStatus = PawJournalStatus.loading,
    this.checks = const [],
    this.journalError,
    this.loggedCheckId,
  });

  final PawScanStatus status;

  /// Held in memory only. Nothing is uploaded until the owner confirms.
  final List<PickedFile> photos;

  final PawScanDraft? draft;

  /// The owner's own answer about which paw this is.
  final PawLocation location;

  /// Readable copy, never a stringified exception.
  final String? errorMessage;

  final PawJournalStatus journalStatus;

  /// Newest first.
  final List<PawCheck> checks;
  final String? journalError;

  /// Set once the draft has been written, which unlocks the follow-up actions.
  final EntityId? loggedCheckId;

  bool get isBusy =>
      status == PawScanStatus.capturing ||
      status == PawScanStatus.analyzing ||
      status == PawScanStatus.saving;

  bool get hasPhotos => photos.isNotEmpty;

  bool get canAddPhoto => photos.length < kMaxPawScanPhotos && !isBusy;

  bool get canAnalyze => hasPhotos && !isBusy;

  bool get hasDraft => draft != null;

  /// Whether a reviewable result is on screen.
  bool get hasResult => draft != null && draft!.isUsable;

  bool get isLogged => loggedCheckId != null;

  PawScanState copyWith({
    PawScanStatus? status,
    List<PickedFile>? photos,
    PawScanDraft? draft,
    PawLocation? location,
    String? errorMessage,
    PawJournalStatus? journalStatus,
    List<PawCheck>? checks,
    String? journalError,
    EntityId? loggedCheckId,
    bool clearDraft = false,
    bool clearErrorMessage = false,
    bool clearJournalError = false,
    bool clearLoggedCheckId = false,
  }) {
    return PawScanState(
      status: status ?? this.status,
      photos: photos ?? this.photos,
      draft: clearDraft ? null : draft ?? this.draft,
      location: location ?? this.location,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      journalStatus: journalStatus ?? this.journalStatus,
      checks: checks ?? this.checks,
      journalError:
          clearJournalError ? null : journalError ?? this.journalError,
      loggedCheckId:
          clearLoggedCheckId ? null : loggedCheckId ?? this.loggedCheckId,
    );
  }
}

class PawScanCubit extends Cubit<PawScanState> {
  PawScanCubit({
    required PawCheckRepository pawCheckRepository,
    required PawScanAiRepository aiRepository,
    required PawPhotoPicker picker,
    required AuthRepository authRepository,
    required PawPhotoUploadService uploadService,
    AnalyticsService? analytics,
  })  : _pawCheckRepository = pawCheckRepository,
        _aiRepository = aiRepository,
        _picker = picker,
        _authRepository = authRepository,
        _uploadService = uploadService,
        _analytics = analytics ?? const NoopAnalyticsService(),
        super(const PawScanState());

  final PawCheckRepository _pawCheckRepository;
  final PawScanAiRepository _aiRepository;
  final PawPhotoPicker _picker;
  final AuthRepository _authRepository;
  final PawPhotoUploadService _uploadService;
  final AnalyticsService _analytics;

  StreamSubscription<List<PawCheck>>? _checksSubscription;
  EntityId? _userId;

  /// Subscribes to the pet's saved paw checks for the journal.
  Future<void> load(String petId) async {
    emit(state.copyWith(journalStatus: PawJournalStatus.loading));

    try {
      await _pawCheckRepository.initialize();
      final user = await _currentUserId();
      await _checksSubscription?.cancel();
      _checksSubscription = _pawCheckRepository
          .watchChecks(userId: user, petId: EntityId(petId))
          .listen(
        (checks) {
          final sorted = [...checks]
            ..sort((a, b) => b.checkedAt.compareTo(a.checkedAt));
          emit(
            state.copyWith(
              journalStatus: PawJournalStatus.ready,
              checks: sorted,
              clearJournalError: true,
            ),
          );
        },
        onError: (Object error) {
          emit(
            state.copyWith(
              journalStatus: PawJournalStatus.failure,
              journalError: _friendlyError(error),
            ),
          );
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          journalStatus: PawJournalStatus.failure,
          journalError: _friendlyError(error),
        ),
      );
    }
  }

  void setLocation(PawLocation location) {
    emit(state.copyWith(location: location));
  }

  /// Captures one more photo. Analysis is a separate, explicit step: a paw
  /// scan can carry up to four photos, and re-analysing after each one would
  /// multiply the cost of a paid multimodal request for no benefit.
  Future<void> addPhoto(PawPhotoSource source) async {
    if (state.photos.length >= kMaxPawScanPhotos) {
      emit(
        state.copyWith(
          status: PawScanStatus.failure,
          errorMessage: 'A scan can hold up to $kMaxPawScanPhotos photos.',
        ),
      );
      return;
    }

    final previousStatus = state.status;
    emit(state.copyWith(status: PawScanStatus.capturing));

    try {
      final picked = await _picker.pick(source);

      if (picked == null) {
        // Cancelled: leave the photos already taken alone.
        emit(state.copyWith(status: previousStatus));
        return;
      }

      emit(
        state.copyWith(
          status: PawScanStatus.idle,
          photos: [...state.photos, picked],
          clearDraft: true,
          clearErrorMessage: true,
          clearLoggedCheckId: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PawScanStatus.failure,
          errorMessage: _friendlyError(error),
        ),
      );
    }
  }

  void removePhoto(int index) {
    if (index < 0 || index >= state.photos.length) return;

    final photos = [...state.photos]..removeAt(index);
    emit(
      state.copyWith(
        status: PawScanStatus.idle,
        photos: photos,
        clearDraft: true,
        clearErrorMessage: true,
        clearLoggedCheckId: true,
      ),
    );
  }

  /// Sends the captured photos for description.
  Future<void> analyze({String? speciesLabel}) async {
    if (state.photos.isEmpty) {
      emit(
        state.copyWith(
          status: PawScanStatus.failure,
          errorMessage: "Add at least one photo of your pet's paw.",
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: PawScanStatus.analyzing,
        clearDraft: true,
        clearErrorMessage: true,
        clearLoggedCheckId: true,
      ),
    );

    try {
      final draft = await _aiRepository.analyzePaw(
        photos: [
          for (final photo in state.photos)
            PawPhoto(bytes: photo.bytes, mimeType: photo.contentType),
        ],
        location: state.location,
        speciesLabel: speciesLabel,
      );

      if (draft.isUsable) {
        _analytics.logEvent(
          AnalyticsEvents.pawScanAnalyzed,
          parameters: {
            AnalyticsParams.level: draft.attentionLevel.name,
            AnalyticsParams.photoCount: state.photos.length,
          },
        );
        if (draft.safetyFilterApplied) {
          // Rising counts here mean the prompt or the model has drifted and
          // the scrub is the only thing holding the line.
          _analytics.logEvent(AnalyticsEvents.pawScanFiltered);
        }
      } else {
        _analytics.logEvent(
          AnalyticsEvents.pawScanRejected,
          parameters: {AnalyticsParams.type: draft.status.name},
        );
      }

      emit(
        state.copyWith(
          status:
              draft.isUsable ? PawScanStatus.review : PawScanStatus.rejected,
          draft: draft,
        ),
      );
    } catch (error) {
      // Keep the photos so the owner can retry without re-shooting.
      emit(
        state.copyWith(
          status: PawScanStatus.failure,
          errorMessage: _friendlyError(error),
        ),
      );
    }
  }

  /// Writes the reviewed result to the journal, uploading its photos first.
  Future<void> logCheck(
    String petId, {
    String? ownerNote,
    bool includeInVetSummary = false,
  }) async {
    final draft = state.draft;

    if (draft == null || !draft.canBeLogged) {
      emit(
        state.copyWith(
          status: PawScanStatus.failure,
          errorMessage: 'There is no result to save yet.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: PawScanStatus.saving, clearErrorMessage: true));

    var uploadedPaths = const <String>[];

    try {
      final user = await _currentUserId();
      final now = DateTime.now().toUtc();
      final checkId = EntityId('${now.microsecondsSinceEpoch}');

      final uploaded = await _uploadService.uploadPawPhotos(
        userId: user,
        petId: EntityId(petId),
        checkId: checkId,
        files: state.photos,
      );
      uploadedPaths = uploaded.map((file) => file.path).toList();

      final note = ownerNote?.trim();

      await _pawCheckRepository.saveCheck(
        PawCheck(
          id: checkId,
          userId: user,
          petId: EntityId(petId),
          location: draft.location,
          attentionLevel: draft.attentionLevel,
          checkedAt: UtcDateTime.unchecked(now),
          photoUrls: uploaded.map((file) => file.downloadUrl).toList(),
          photoStoragePaths: uploadedPaths,
          observations: draft.observations.map((o) => o.text).toList(),
          summary: draft.summary,
          ownerNote: note == null || note.isEmpty ? null : note,
          includeInVetSummary: includeInVetSummary,
          confidence: draft.confidence ?? 0,
          status: PawCheckStatus.confirmed,
        ),
      );

      _analytics.logEvent(
        AnalyticsEvents.pawCheckLogged,
        parameters: {AnalyticsParams.level: draft.attentionLevel.name},
      );

      emit(
        state.copyWith(status: PawScanStatus.saved, loggedCheckId: checkId),
      );
    } catch (error) {
      // The photos are already in storage but the record never landed, so
      // clean them up rather than leaving orphaned bytes behind.
      await _uploadService.deletePawPhotos(uploadedPaths);
      emit(
        state.copyWith(
          status: PawScanStatus.failure,
          errorMessage: _friendlyError(error),
        ),
      );
    }
  }

  /// Drops the result without writing or uploading anything.
  void discardDraft() {
    emit(
      state.copyWith(
        status: PawScanStatus.idle,
        photos: const [],
        clearDraft: true,
        clearErrorMessage: true,
        clearLoggedCheckId: true,
      ),
    );
  }

  Future<void> setIncludeInVetSummary(
    PawCheck check, {
    required bool include,
  }) async {
    try {
      await _pawCheckRepository.saveCheck(
        check.copyWith(includeInVetSummary: include),
      );
    } catch (error) {
      emit(state.copyWith(errorMessage: _friendlyError(error)));
    }
  }

  Future<void> deleteCheck(PawCheck check) async {
    try {
      await _pawCheckRepository.deleteCheck(
        userId: check.userId,
        petId: check.petId,
        checkId: check.id,
      );
      await _uploadService.deletePawPhotos(check.photoStoragePaths);
    } catch (error) {
      emit(state.copyWith(errorMessage: _friendlyError(error)));
    }
  }

  Future<EntityId> _currentUserId() async {
    final cached = _userId;
    if (cached != null) return cached;

    final user = await _authRepository.currentUser() ??
        await _authRepository.signInAnonymously();
    final id = EntityId(user.id);
    _userId = id;
    return id;
  }

  /// Maps an exception to copy the owner can act on.
  ///
  /// Paw Scan never shows `error.toString()`: a raw Firebase exception on a
  /// health-adjacent screen is alarming, unhelpful, and leaks internals.
  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();

    if (text.contains('network') ||
        text.contains('unavailable') ||
        text.contains('socket') ||
        text.contains('timeout')) {
      return 'Paw Scan needs an internet connection. Try again when you are '
          'back online.';
    }

    if (text.contains('permission')) {
      return 'PawVault could not access that photo. Check the app permissions '
          'and try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  @override
  Future<void> close() async {
    await _checksSubscription?.cancel();
    return super.close();
  }
}
