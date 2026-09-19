import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_events.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/paw_scan/application/paw_photo_upload_service.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_observation.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_photo.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_scan_draft.dart';
import 'package:paw_vault/features/paw_scan/domain/repositories/paw_check_repository.dart';
import 'package:paw_vault/features/paw_scan/domain/repositories/paw_scan_ai_repository.dart';
import 'package:paw_vault/features/paw_scan/domain/services/paw_photo_picker.dart';
import 'package:paw_vault/features/paw_scan/presentation/cubit/paw_scan_cubit.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';

PickedFile _picked() => PickedFile(
      bytes: Uint8List.fromList(const [1, 2, 3]),
      fileName: 'paw.jpg',
      extension: 'jpg',
      contentType: 'image/jpeg',
    );

PawScanDraft _reviewDraft({
  PawAttentionLevel level = PawAttentionLevel.monitor,
  bool safetyFilterApplied = false,
}) {
  return PawScanDraft(
    observations: const [
      PawObservation(
        area: PawObservationArea.pad,
        text: 'A dark area near the centre of the pad.',
      ),
    ],
    attentionLevel: level,
    summary: 'One pad looks different from the others.',
    confidence: 0.8,
    safetyFilterApplied: safetyFilterApplied,
  );
}

PawCheck _check({
  String id = 'check-1',
  bool includeInVetSummary = false,
  DateTime? checkedAt,
}) {
  return PawCheck(
    id: EntityId(id),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    location: PawLocation.frontLeft,
    attentionLevel: PawAttentionLevel.monitor,
    checkedAt: UtcDateTime(checkedAt ?? DateTime.utc(2026, 9, 18)),
    photoStoragePaths: ['users/user-1/pets/pet-1/pawChecks/$id/0.jpg'],
    includeInVetSummary: includeInVetSummary,
    status: PawCheckStatus.confirmed,
  );
}

({
  PawScanCubit cubit,
  _FakePawCheckRepository repository,
  _FakePawScanAiRepository ai,
  _FakePawPhotoPicker picker,
  _FakeStorageRepository storage,
  _RecordingAnalyticsService analytics,
}) _build() {
  final repository = _FakePawCheckRepository();
  final ai = _FakePawScanAiRepository();
  final picker = _FakePawPhotoPicker();
  final storage = _FakeStorageRepository();
  final analytics = _RecordingAnalyticsService();

  return (
    cubit: PawScanCubit(
      pawCheckRepository: repository,
      aiRepository: ai,
      petRepository: _FakePetRepository(),
      picker: picker,
      authRepository: _FakeAuthRepository(),
      uploadService: PawPhotoUploadService(storageRepository: storage),
      analytics: analytics,
    ),
    repository: repository,
    ai: ai,
    picker: picker,
    storage: storage,
    analytics: analytics,
  );
}

void main() {
  group('capture', () {
    test('appends a captured photo', () async {
      final t = _build();
      t.picker.next = _picked();

      await t.cubit.addPhoto(PawPhotoSource.camera);

      expect(t.cubit.state.photos, hasLength(1));
      expect(t.cubit.state.status, PawScanStatus.idle);
      await t.cubit.close();
    });

    test('a cancelled capture leaves existing photos untouched', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);

      t.picker.next = null;
      await t.cubit.addPhoto(PawPhotoSource.gallery);

      expect(t.cubit.state.photos, hasLength(1));
      expect(t.cubit.state.status, PawScanStatus.idle);
      await t.cubit.close();
    });

    test('refuses more than the photo cap and does not open the picker',
        () async {
      final t = _build();
      t.picker.next = _picked();
      for (var i = 0; i < kMaxPawScanPhotos; i++) {
        await t.cubit.addPhoto(PawPhotoSource.camera);
      }
      final callsSoFar = t.picker.pickCallCount;

      await t.cubit.addPhoto(PawPhotoSource.camera);

      expect(t.cubit.state.status, PawScanStatus.failure);
      expect(t.cubit.state.photos, hasLength(kMaxPawScanPhotos));
      expect(t.picker.pickCallCount, callsSoFar);
      await t.cubit.close();
    });

    test('removing a photo drops the stale result', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.next = _reviewDraft();
      await t.cubit.analyze();

      t.cubit.removePhoto(0);

      expect(t.cubit.state.photos, isEmpty);
      expect(t.cubit.state.draft, isNull);
      await t.cubit.close();
    });
  });

  group('analyze', () {
    test('sends every photo in one request and lands on review', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.next = _reviewDraft();

      await t.cubit.analyze(speciesLabel: 'dog');

      expect(t.ai.analyzeCallCount, 1);
      expect(t.ai.receivedPhotos, hasLength(2));
      expect(t.ai.receivedSpecies, 'dog');
      expect(t.cubit.state.status, PawScanStatus.review);
      expect(t.cubit.state.hasResult, isTrue);
      await t.cubit.close();
    });

    test('passes the owner\'s paw answer through', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.cubit.setLocation(PawLocation.rearRight);
      t.ai.next = _reviewDraft();

      await t.cubit.analyze();

      expect(t.ai.receivedLocation, PawLocation.rearRight);
      await t.cubit.close();
    });

    test('sends the pet\'s species as context by default', () async {
      // A cat's paw does not look like a dog's, and the pet record already
      // knows which this is.
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.next = _reviewDraft();

      await t.cubit.analyze();

      expect(t.ai.receivedSpecies, 'dog');
      await t.cubit.close();
    });

    test('an explicit species overrides the pet record', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.next = _reviewDraft();

      await t.cubit.analyze(speciesLabel: 'cat');

      expect(t.ai.receivedSpecies, 'cat');
      await t.cubit.close();
    });

    test('refuses with no photos and never calls the model', () async {
      final t = _build();

      await t.cubit.analyze();

      expect(t.cubit.state.status, PawScanStatus.failure);
      expect(t.cubit.state.errorMessage, contains('at least one photo'));
      expect(t.ai.analyzeCallCount, 0);
      await t.cubit.close();
    });

    test('keeps the photos when the model call fails', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.throwsOnAnalyze = true;

      await t.cubit.analyze();

      expect(t.cubit.state.status, PawScanStatus.failure);
      expect(t.cubit.state.photos, hasLength(1));
      await t.cubit.close();
    });

    test('shows readable copy instead of the raw exception', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.throwsOnAnalyze = true;

      await t.cubit.analyze();

      final message = t.cubit.state.errorMessage!;
      expect(message, isNot(contains('Exception')));
      expect(message, isNot(contains('_FakePawScanAiRepository')));
      await t.cubit.close();
    });

    test('a network failure says so', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.analyzeError = Exception('network unavailable');

      await t.cubit.analyze();

      expect(t.cubit.state.errorMessage, contains('internet connection'));
      await t.cubit.close();
    });

    group('a rejected scan shows no verdict', () {
      test('for an unusable photo', () async {
        final t = _build();
        t.picker.next = _picked();
        await t.cubit.addPhoto(PawPhotoSource.camera);
        t.ai.next = const PawScanDraft.unusable(
          photoQuality: PawScanPhotoQuality.notAPaw,
        );

        await t.cubit.analyze();

        expect(t.cubit.state.status, PawScanStatus.rejected);
        expect(t.cubit.state.hasResult, isFalse);
        await t.cubit.close();
      });

      test('when no attention level could be established', () async {
        // An unreadable reply must land in `rejected`, not `review`: a review
        // screen with no observations reads as "nothing stood out".
        final t = _build();
        t.picker.next = _picked();
        await t.cubit.addPhoto(PawPhotoSource.camera);
        // `attentionLevel` defaults to undetermined — the state a failed
        // parse leaves behind.
        t.ai.next =
            const PawScanDraft(status: PawScanDraftStatus.lowConfidenceReview);

        await t.cubit.analyze();

        expect(t.cubit.state.status, PawScanStatus.rejected);
        expect(t.cubit.state.hasResult, isFalse);
        expect(t.cubit.state.draft!.canBeLogged, isFalse);
        await t.cubit.close();
      });

      test('when the model refused', () async {
        final t = _build();
        t.picker.next = _picked();
        await t.cubit.addPhoto(PawPhotoSource.camera);
        t.ai.next = const PawScanDraft.blocked();

        await t.cubit.analyze();

        expect(t.cubit.state.status, PawScanStatus.rejected);
        expect(t.cubit.state.hasResult, isFalse);
        await t.cubit.close();
      });
    });
  });

  group('logCheck', () {
    test('uploads the photos then saves a confirmed check', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.next = _reviewDraft(level: PawAttentionLevel.vetSoon);
      await t.cubit.analyze();

      await t.cubit.logCheck('pet-1', ownerNote: '  She was licking it.  ');

      expect(t.storage.uploadedPaths, hasLength(1));
      final saved = t.repository.savedCheck!;
      expect(saved.status, PawCheckStatus.confirmed);
      expect(saved.attentionLevel, PawAttentionLevel.vetSoon);
      expect(saved.observations, hasLength(1));
      expect(saved.ownerNote, 'She was licking it.');
      expect(saved.includeInVetSummary, isFalse);
      expect(saved.photoStoragePaths, t.storage.uploadedPaths);
      expect(t.cubit.state.status, PawScanStatus.saved);
      expect(t.cubit.state.isLogged, isTrue);
      await t.cubit.close();
    });

    test('stores an empty owner note as null', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.next = _reviewDraft();
      await t.cubit.analyze();

      await t.cubit.logCheck('pet-1', ownerNote: '   ');

      expect(t.repository.savedCheck!.ownerNote, isNull);
      await t.cubit.close();
    });

    test('can opt the check into the vet summary', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.next = _reviewDraft();
      await t.cubit.analyze();

      await t.cubit.logCheck('pet-1', includeInVetSummary: true);

      expect(t.repository.savedCheck!.includeInVetSummary, isTrue);
      await t.cubit.close();
    });

    test('deletes the uploaded photos when the save fails', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.next = _reviewDraft();
      await t.cubit.analyze();
      t.repository.throwsOnSave = true;

      await t.cubit.logCheck('pet-1');

      expect(t.storage.uploadedPaths, hasLength(1));
      expect(t.storage.deletedPaths, t.storage.uploadedPaths);
      expect(t.cubit.state.status, PawScanStatus.failure);
      await t.cubit.close();
    });

    test('refuses every rejected draft without uploading or saving', () async {
      const rejected = [
        PawScanDraft.unusable(photoQuality: PawScanPhotoQuality.notAPaw),
        PawScanDraft.unusable(photoQuality: PawScanPhotoQuality.blurry),
        PawScanDraft.blocked(),
        // A "no result" check would sit in the journal looking like a check
        // that found nothing — which a vet could read as a negative finding.
        PawScanDraft(status: PawScanDraftStatus.lowConfidenceReview),
      ];

      for (final draft in rejected) {
        final t = _build();
        t.picker.next = _picked();
        await t.cubit.addPhoto(PawPhotoSource.camera);
        t.ai.next = draft;
        await t.cubit.analyze();

        await t.cubit.logCheck('pet-1');

        expect(t.storage.uploadedPaths, isEmpty, reason: '${draft.status}');
        expect(t.repository.savedCheck, isNull, reason: '${draft.status}');
        expect(t.cubit.state.status, PawScanStatus.failure);
        await t.cubit.close();
      }
    });

    test('refuses when there is no result at all', () async {
      final t = _build();

      await t.cubit.logCheck('pet-1');

      expect(t.storage.uploadedPaths, isEmpty);
      expect(t.repository.savedCheck, isNull);
      await t.cubit.close();
    });
  });

  group('discardDraft', () {
    test('writes and uploads nothing', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.next = _reviewDraft();
      await t.cubit.analyze();

      t.cubit.discardDraft();

      expect(t.cubit.state.status, PawScanStatus.idle);
      expect(t.cubit.state.draft, isNull);
      expect(t.cubit.state.photos, isEmpty);
      expect(t.storage.uploadedPaths, isEmpty);
      expect(t.repository.savedCheck, isNull);
      await t.cubit.close();
    });
  });

  group('journal', () {
    test('loads checks newest first', () async {
      final t = _build();
      t.repository.checks = [
        _check(id: 'older', checkedAt: DateTime.utc(2026, 9, 2)),
        _check(id: 'newer', checkedAt: DateTime.utc(2026, 9, 18)),
      ];

      await t.cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(t.cubit.state.journalStatus, PawJournalStatus.ready);
      expect(
        t.cubit.state.checks.map((c) => c.id.value),
        ['newer', 'older'],
      );
      await t.cubit.close();
    });

    test('loads the pet so the follow-up reminder can name it', () async {
      final t = _build();

      await t.cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(t.cubit.state.pet?.name, 'Bella');
      expect(t.cubit.state.petName, 'Bella');
      await t.cubit.close();
    });

    test('falls back to a neutral pet name when there is no pet', () async {
      final t = _build();

      expect(t.cubit.state.petName, 'your pet');
      await t.cubit.close();
    });

    test('a stream error only affects the journal', () async {
      final t = _build();
      t.repository.throwsOnWatch = true;

      await t.cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(t.cubit.state.journalStatus, PawJournalStatus.failure);
      expect(t.cubit.state.journalError, isNotNull);
      expect(t.cubit.state.status, PawScanStatus.idle);
      await t.cubit.close();
    });

    test('toggling vet-summary inclusion re-saves the check', () async {
      final t = _build();

      await t.cubit.setIncludeInVetSummary(_check(), include: true);

      expect(t.repository.savedCheck!.includeInVetSummary, isTrue);
      await t.cubit.close();
    });

    test('deleting a check removes its photos too', () async {
      final t = _build();
      final check = _check();

      await t.cubit.deleteCheck(check);

      expect(t.repository.deletedCheckId, check.id);
      expect(t.storage.deletedPaths, check.photoStoragePaths);
      await t.cubit.close();
    });
  });

  group('analytics', () {
    test('logs the attention level of a reviewable result', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.next = _reviewDraft(level: PawAttentionLevel.vetPromptly);

      await t.cubit.analyze();

      expect(t.analytics.names, contains(AnalyticsEvents.pawScanAnalyzed));
      expect(
        t.analytics.parametersFor(
          AnalyticsEvents.pawScanAnalyzed,
        )?[AnalyticsParams.level],
        'vetPromptly',
      );
      await t.cubit.close();
    });

    test('never logs observation text', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.next = _reviewDraft();

      await t.cubit.analyze();
      await t.cubit.logCheck('pet-1', ownerNote: 'private note');

      final allValues = t.analytics.logged
          .expand((entry) => entry.parameters?.values ?? const [])
          .map((value) => '$value')
          .join(' ');
      expect(allValues, isNot(contains('dark area')));
      expect(allValues, isNot(contains('private note')));
      await t.cubit.close();
    });

    test('raises the filter alarm when the scrub fires', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.next = _reviewDraft(safetyFilterApplied: true);

      await t.cubit.analyze();

      expect(t.analytics.names, contains(AnalyticsEvents.pawScanFiltered));
      await t.cubit.close();
    });

    test('logs a rejection type instead of a level', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.next = const PawScanDraft.blocked();

      await t.cubit.analyze();

      expect(t.analytics.names, contains(AnalyticsEvents.pawScanRejected));
      expect(
        t.analytics.names,
        isNot(contains(AnalyticsEvents.pawScanAnalyzed)),
      );
      await t.cubit.close();
    });

    test('logs the confirmed check', () async {
      final t = _build();
      t.picker.next = _picked();
      await t.cubit.addPhoto(PawPhotoSource.camera);
      t.ai.next = _reviewDraft();
      await t.cubit.analyze();

      await t.cubit.logCheck('pet-1');

      expect(t.analytics.names, contains(AnalyticsEvents.pawCheckLogged));
      await t.cubit.close();
    });
  });
}

class _FakePawCheckRepository implements PawCheckRepository {
  List<PawCheck> checks = const [];
  PawCheck? savedCheck;
  EntityId? deletedCheckId;
  bool throwsOnWatch = false;
  bool throwsOnSave = false;

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PawCheck>> watchChecks({
    required EntityId userId,
    required EntityId petId,
  }) {
    if (throwsOnWatch) {
      return Stream.error(Exception('watch failed'));
    }
    return Stream.value(checks);
  }

  @override
  Future<PawCheck?> getCheck({
    required EntityId userId,
    required EntityId petId,
    required EntityId checkId,
  }) async {
    return null;
  }

  @override
  Future<void> saveCheck(PawCheck check) async {
    if (throwsOnSave) {
      throw Exception('save failed');
    }
    savedCheck = check;
  }

  @override
  Future<void> deleteCheck({
    required EntityId userId,
    required EntityId petId,
    required EntityId checkId,
  }) async {
    deletedCheckId = checkId;
  }
}

class _FakePetRepository implements PetRepository {
  @override
  Future<void> initialize() async {}

  @override
  Stream<List<Pet>> watchPets(EntityId userId) => Stream.value(const []);

  @override
  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  }) async {
    return Pet(
      id: petId,
      userId: userId,
      name: 'Bella',
      species: 'dog',
    );
  }

  @override
  Future<void> savePet(Pet pet) async {}

  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) async {}
}

class _FakePawScanAiRepository implements PawScanAiRepository {
  PawScanDraft? next;
  int analyzeCallCount = 0;
  List<PawPhoto> receivedPhotos = const [];
  PawLocation? receivedLocation;
  String? receivedSpecies;
  bool throwsOnAnalyze = false;
  Object? analyzeError;

  @override
  Future<PawScanDraft> analyzePaw({
    required List<PawPhoto> photos,
    required PawLocation location,
    String? speciesLabel,
  }) async {
    analyzeCallCount++;
    receivedPhotos = photos;
    receivedLocation = location;
    receivedSpecies = speciesLabel;

    final error = analyzeError;
    if (error != null) throw error;
    if (throwsOnAnalyze) throw Exception('analyze failed');

    return next ?? const PawScanDraft();
  }
}

class _FakePawPhotoPicker implements PawPhotoPicker {
  PickedFile? next;
  int pickCallCount = 0;

  @override
  Future<PickedFile?> pick(PawPhotoSource source) async {
    pickCallCount++;
    return next;
  }
}

class _FakeStorageRepository implements StorageRepository {
  final List<String> uploadedPaths = [];
  final List<String> deletedPaths = [];

  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadedPaths.add(path);
    return StorageFile(
      path: path,
      downloadUrl: Uri.parse('https://example.com/$path'),
    );
  }

  @override
  Future<void> delete(String path) async {
    deletedPaths.add(path);
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AppUser?> currentUser() async {
    return const AppUser(id: 'user-1', isAnonymous: true);
  }

  @override
  Future<AppUser> signInAnonymously() async {
    return const AppUser(id: 'user-1', isAnonymous: true);
  }

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() => const Stream.empty();
}

class _LoggedEvent {
  const _LoggedEvent(this.name, this.parameters);

  final String name;
  final Map<String, Object?>? parameters;
}

class _RecordingAnalyticsService implements AnalyticsService {
  final List<_LoggedEvent> logged = [];

  Iterable<String> get names => logged.map((entry) => entry.name);

  Map<String, Object?>? parametersFor(String name) =>
      logged.firstWhere((entry) => entry.name == name).parameters;

  @override
  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
    logged.add(_LoggedEvent(name, parameters));
  }

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> setUserId(String? userId) async {}
}
