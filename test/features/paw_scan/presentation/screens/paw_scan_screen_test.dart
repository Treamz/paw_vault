import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_observation.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_photo.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_scan_draft.dart';
import 'package:paw_vault/features/paw_scan/domain/paw_scan_copy.dart';
import 'package:paw_vault/features/paw_scan/domain/repositories/paw_check_repository.dart';
import 'package:paw_vault/features/paw_scan/domain/repositories/paw_scan_ai_repository.dart';
import 'package:paw_vault/features/paw_scan/domain/services/paw_photo_picker.dart';
import 'package:paw_vault/features/paw_scan/presentation/screens/paw_scan_screen.dart';
import 'package:paw_vault/features/paw_scan/presentation/widgets/paw_scan_disclaimer.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';

/// A real 1x1 PNG: the photo strip decodes the bytes, so a placeholder list
/// would fail the image codec rather than the assertion under test.
final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8AAAwAB/AF+0B0a'
  'AAAAAElFTkSuQmCC',
);

PickedFile _picked() => PickedFile(
      bytes: Uint8List.fromList(_pngBytes),
      fileName: 'paw.png',
      extension: 'png',
      contentType: 'image/png',
    );

PawCheck _check() {
  return PawCheck(
    id: const EntityId('check-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    location: PawLocation.frontLeft,
    attentionLevel: PawAttentionLevel.monitor,
    checkedAt: UtcDateTime(DateTime.utc(2026, 9, 18)),
    observations: const ['A dark area near the centre of the pad.'],
    status: PawCheckStatus.confirmed,
  );
}

Widget _app({
  required _FakePawScanAiRepository ai,
  _FakePawCheckRepository? repository,
  _FakePawPhotoPicker? picker,
}) {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<PawCheckRepository>.value(
        value: repository ?? _FakePawCheckRepository(),
      ),
      RepositoryProvider<PawScanAiRepository>.value(value: ai),
      RepositoryProvider<PetRepository>.value(value: _FakePetRepository()),
      RepositoryProvider<PawPhotoPicker>.value(
        value: picker ?? _FakePawPhotoPicker(),
      ),
      RepositoryProvider<AuthRepository>.value(value: _FakeAuthRepository()),
      RepositoryProvider<StorageRepository>.value(
        value: _FakeStorageRepository(),
      ),
      RepositoryProvider<AnalyticsService>.value(
        value: const NoopAnalyticsService(),
      ),
    ],
    child: const MaterialApp(home: PawScanScreen(petId: 'pet-1')),
  );
}

/// Gives the test a phone-tall surface. The Scan tab is a [ListView], and at
/// the default 800x600 the actions below the photo strip are never built, so
/// finders for them would miss for the wrong reason.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Drives a capture and an analysis so the result section is on screen.
Future<void> _analyze(WidgetTester tester, _FakePawPhotoPicker picker) async {
  picker.next = _picked();
  await tester.tap(find.text('Add paw photo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Take a photo'));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Describe'));
  await tester.pumpAndSettle();
}

void main() {
  group('the disclaimer', () {
    testWidgets('is on screen before anything is captured', (tester) async {
      await tester.pumpWidget(_app(ai: _FakePawScanAiRepository()));
      await tester.pumpAndSettle();

      expect(find.text(PawScanCopy.disclaimerTitle), findsOneWidget);
      expect(
        find.textContaining('not a substitute for your vet'),
        findsOneWidget,
      );
    });

    testWidgets('offers no way to dismiss it', (tester) async {
      // The notice is the basis on which this feature is allowed to exist.
      // If a close affordance ever appears here, that is a bug, not a tidy-up.
      await tester.pumpWidget(_app(ai: _FakePawScanAiRepository()));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(PawScanDisclaimer),
          matching: find.byType(IconButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(PawScanDisclaimer),
          matching: find.byIcon(Icons.close),
        ),
        findsNothing,
      );
    });

    testWidgets('is still there on the most urgent result', (tester) async {
      _useTallSurface(tester);
      // Regression guard for the highest-risk path: a "contact a vet
      // promptly" verdict must never render without the notice.
      final ai = _FakePawScanAiRepository()
        ..next = _draft(level: PawAttentionLevel.vetPromptly);
      final picker = _FakePawPhotoPicker();
      await tester.pumpWidget(_app(ai: ai, picker: picker));
      await tester.pumpAndSettle();

      await _analyze(tester, picker);

      expect(find.text('Contact a vet promptly'), findsOneWidget);
      expect(find.byType(PawScanDisclaimer), findsWidgets);
    });

    testWidgets('sits above the observations on a result', (tester) async {
      _useTallSurface(tester);
      // A notice at the top of a scrolling screen is off-screen by the time
      // the descriptions are read, which is when it matters most.
      final ai = _FakePawScanAiRepository()..next = _draft();
      final picker = _FakePawPhotoPicker();
      await tester.pumpWidget(_app(ai: ai, picker: picker));
      await tester.pumpAndSettle();

      await _analyze(tester, picker);

      final disclaimers =
          tester.widgetList(find.byType(PawScanDisclaimer)).length;
      expect(disclaimers, greaterThanOrEqualTo(2));

      final observationsHeader =
          tester.getTopLeft(find.text('What Paw Scan can see')).dy;
      final lastDisclaimer = find.byType(PawScanDisclaimer).last;
      expect(
        tester.getTopLeft(lastDisclaimer).dy,
        lessThan(observationsHeader),
      );
    });
  });

  group('results', () {
    testWidgets('renders the observations and the not-saved notice',
        (tester) async {
      _useTallSurface(tester);
      final ai = _FakePawScanAiRepository()..next = _draft();
      final picker = _FakePawPhotoPicker();
      await tester.pumpWidget(_app(ai: ai, picker: picker));
      await tester.pumpAndSettle();

      await _analyze(tester, picker);

      expect(
        find.textContaining('A dark area near the centre of the pad.'),
        findsOneWidget,
      );
      expect(find.text(PawScanCopy.nothingSavedYet), findsOneWidget);
      expect(find.text('Log this check'), findsOneWidget);
    });

    testWidgets('warns when the safety filter rewrote something',
        (tester) async {
      _useTallSurface(tester);
      final ai = _FakePawScanAiRepository()
        ..next = _draft(safetyFilterApplied: true);
      final picker = _FakePawPhotoPicker();
      await tester.pumpWidget(_app(ai: ai, picker: picker));
      await tester.pumpAndSettle();

      await _analyze(tester, picker);

      expect(
        find.textContaining('read as a medical opinion'),
        findsOneWidget,
      );
    });
  });

  group('rejections show no verdict', () {
    testWidgets('a non-paw photo asks for a retake', (tester) async {
      _useTallSurface(tester);
      final ai = _FakePawScanAiRepository()
        ..next = const PawScanDraft.unusable(
          photoQuality: PawScanPhotoQuality.notAPaw,
        );
      final picker = _FakePawPhotoPicker();
      await tester.pumpWidget(_app(ai: ai, picker: picker));
      await tester.pumpAndSettle();

      await _analyze(tester, picker);

      expect(find.text('That does not look like a paw'), findsOneWidget);
      expect(find.text('Log this check'), findsNothing);
      for (final level in PawAttentionLevel.values) {
        expect(
          find.text(formatPawAttentionLevel(level)),
          findsNothing,
          reason: 'a rejected scan must show no attention level',
        );
      }
    });

    testWidgets('a blocked reply tells the owner to call their vet',
        (tester) async {
      _useTallSurface(tester);
      final ai = _FakePawScanAiRepository()
        ..next = const PawScanDraft.blocked();
      final picker = _FakePawPhotoPicker();
      await tester.pumpWidget(_app(ai: ai, picker: picker));
      await tester.pumpAndSettle();

      await _analyze(tester, picker);

      expect(find.text('Could not analyse this photo'), findsOneWidget);
      expect(find.textContaining('contact your vet now'), findsOneWidget);
      expect(find.text('Log this check'), findsNothing);
    });
  });

  group('journal', () {
    testWidgets('shows an empty state with no checks', (tester) async {
      await tester.pumpWidget(_app(ai: _FakePawScanAiRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Journal'));
      await tester.pumpAndSettle();

      expect(find.text('No paw checks yet'), findsOneWidget);
    });

    testWidgets('lists saved checks with their attention level',
        (tester) async {
      final repository = _FakePawCheckRepository()..checks = [_check()];
      await tester.pumpWidget(
        _app(ai: _FakePawScanAiRepository(), repository: repository),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Journal'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('paw-check-check-1')), findsOneWidget);
      expect(find.textContaining('Front left'), findsOneWidget);
      expect(find.text('Keep an eye on it'), findsOneWidget);
    });
  });
}

PawScanDraft _draft({
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
    confidence: 0.9,
    safetyFilterApplied: safetyFilterApplied,
  );
}

class _FakePawCheckRepository implements PawCheckRepository {
  List<PawCheck> checks = const [];

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PawCheck>> watchChecks({
    required EntityId userId,
    required EntityId petId,
  }) {
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
  Future<void> saveCheck(PawCheck check) async {}

  @override
  Future<void> deleteCheck({
    required EntityId userId,
    required EntityId petId,
    required EntityId checkId,
  }) async {}
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
    return Pet(id: petId, userId: userId, name: 'Bella', species: 'dog');
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

  @override
  Future<PawScanDraft> analyzePaw({
    required List<PawPhoto> photos,
    required PawLocation location,
    String? speciesLabel,
  }) async {
    return next ?? const PawScanDraft();
  }
}

class _FakePawPhotoPicker implements PawPhotoPicker {
  PickedFile? next;

  @override
  Future<PickedFile?> pick(PawPhotoSource source) async => next;
}

class _FakeStorageRepository implements StorageRepository {
  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    return StorageFile(path: path, downloadUrl: Uri.parse('https://x/$path'));
  }

  @override
  Future<void> delete(String path) async {}
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AppUser?> currentUser() async =>
      const AppUser(id: 'user-1', isAnonymous: true);

  @override
  Future<AppUser> signInAnonymously() async =>
      const AppUser(id: 'user-1', isAnonymous: true);

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() => const Stream.empty();
}
