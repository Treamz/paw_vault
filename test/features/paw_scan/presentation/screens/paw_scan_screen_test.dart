import 'dart:async';
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
import 'package:paw_vault/features/paw_scan/presentation/cubit/paw_scan_cubit.dart';
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

PawCheck _check({
  String id = 'check-1',
  DateTime? checkedAt,
  List<String> observations = const ['A dark area near the centre of the pad.'],
}) {
  return PawCheck(
    id: EntityId(id),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    location: PawLocation.frontLeft,
    attentionLevel: PawAttentionLevel.monitor,
    checkedAt: UtcDateTime(checkedAt ?? DateTime.utc(2026, 9, 18)),
    observations: observations,
    status: PawCheckStatus.confirmed,
  );
}

Widget _app({
  required _FakePawScanAiRepository ai,
  _FakePawCheckRepository? repository,
  _FakePawPhotoPicker? picker,
  bool pushed = false,
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
    child: MaterialApp(
      // `pushed` puts the screen on a route that can be popped, so a test can
      // leave it. The ScaffoldMessenger lives above at the MaterialApp, so a
      // message it showed survives the pop unless the screen takes it down.
      home: pushed
          ? Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PawScanScreen(petId: 'pet-1'),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            )
          : const PawScanScreen(petId: 'pet-1'),
    ),
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
  await tester.tap(find.text(PawScanCopy.takePhoto));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Describe'));
  await tester.pumpAndSettle();
}

/// Captures [count] photos, one tap each.
Future<void> _capture(
  WidgetTester tester,
  _FakePawPhotoPicker picker, {
  int count = 1,
}) async {
  picker.next = _picked();
  for (var i = 0; i < count; i++) {
    await tester.tap(
      find.text(i == 0 ? PawScanCopy.takePhoto : PawScanCopy.camera),
    );
    await tester.pumpAndSettle();
  }
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
      expect(find.byType(PawScanDisclaimer), findsOneWidget);
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

      // One notice, not two. The result section renders directly beneath the
      // tab's disclaimer, so a second copy landed immediately below the first
      // and just read as a rendering bug on a real phone.
      expect(find.byType(PawScanDisclaimer), findsOneWidget);

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
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('the saved message does not outlive the screen',
        (tester) async {
      // QA: the "saved" message rode along to the main menu and stayed there
      // until the app was killed. It names this screen's History and its
      // action moves this screen's tabs, so closing the screen takes it down.
      _useTallSurface(tester);
      final ai = _FakePawScanAiRepository()..next = _draft();
      final picker = _FakePawPhotoPicker()..next = _picked();
      await tester.pumpWidget(_app(ai: ai, picker: picker, pushed: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await _analyze(tester, picker);

      final save = find.text('Save');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Paw check saved to History'), findsOneWidget);

      // Leaving the screen takes the message with it.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Paw check saved to History'), findsNothing);
    });

    testWidgets('shows every observation, not just the first', (tester) async {
      // The card is the whole record of a check — there is no detail screen
      // behind it — so truncating to the first observation hid part of what
      // the owner had approved.
      _useTallSurface(tester);
      final repository = _FakePawCheckRepository([
        _check(
          observations: const [
            'A dark area near the centre of the pad.',
            'The nail on this toe is longer than the others.',
            'Some redness between the toes.',
          ],
        ),
      ]);
      await tester.pumpWidget(
        _app(ai: _FakePawScanAiRepository(), repository: repository),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(
        find.text('A dark area near the centre of the pad.'),
        findsOneWidget,
      );
      expect(
        find.text('The nail on this toe is longer than the others.'),
        findsOneWidget,
      );
      expect(find.text('Some redness between the toes.'), findsOneWidget);
    });

    testWidgets('marks the check that was just saved', (tester) async {
      // QA: tapping View landed on a list that looked unchanged, with no way
      // to tell which row was the one just saved.
      _useTallSurface(tester);
      final ai = _FakePawScanAiRepository()..next = _draft();
      final picker = _FakePawPhotoPicker()..next = _picked();
      final repository = _FakePawCheckRepository([_check(id: 'older')]);
      await tester.pumpWidget(
        _app(ai: ai, picker: picker, repository: repository),
      );
      await tester.pumpAndSettle();
      await _analyze(tester, picker);

      final save = find.text('Save');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      // Follow the snackbar's own action, as the owner does.
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();

      final saved = repository.saved.last;
      final savedCard = tester.widget<Card>(
        find.byKey(ValueKey('paw-check-${saved.id.value}')),
      );
      final olderCard = tester.widget<Card>(
        find.byKey(const ValueKey('paw-check-older')),
      );
      expect(
        savedCard.shape,
        isA<RoundedRectangleBorder>(),
        reason: 'the just-saved check is outlined',
      );
      expect(savedCard.color, isNotNull);
      expect(
        olderCard.shape,
        isNull,
        reason: 'older checks are left alone',
      );
    });

    testWidgets('a result is the end of the flow, with nothing after it',
        (tester) async {
      // QA: the capture controls sat below Discard/Save, so the first step
      // looked like it repeated itself. The paw selector there was worse than
      // redundant — the saved check takes its location from the draft, so
      // changing it after a result silently did nothing.
      _useTallSurface(tester);
      final ai = _FakePawScanAiRepository()..next = _draft();
      final picker = _FakePawPhotoPicker()..next = _picked();
      await tester.pumpWidget(_app(ai: ai, picker: picker));
      await tester.pumpAndSettle();

      // With a photo taken but not yet described, the capture step is there.
      await tester.tap(find.text(PawScanCopy.takePhoto));
      await tester.pumpAndSettle();
      expect(find.text('Which paw?'), findsOneWidget);
      expect(find.text(PawScanCopy.camera), findsOneWidget);
      expect(find.textContaining('Describe'), findsOneWidget);

      await tester.tap(find.textContaining('Describe'));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Which paw?'), findsNothing);
      expect(find.text(PawScanCopy.camera), findsNothing);
      expect(find.text(PawScanCopy.gallery), findsNothing);
      expect(find.textContaining('Describe'), findsNothing);
      // The photo stays as context for what the result describes, but with
      // no way to remove it.
      expect(find.byType(Image), findsWidgets);
      expect(find.byTooltip('Remove photo 1'), findsNothing);
    });

    testWidgets('discarding a result returns to the capture step',
        (tester) async {
      _useTallSurface(tester);
      final ai = _FakePawScanAiRepository()..next = _draft();
      final picker = _FakePawPhotoPicker()..next = _picked();
      await tester.pumpWidget(_app(ai: ai, picker: picker));
      await tester.pumpAndSettle();
      await _analyze(tester, picker);

      final discard = find.text('Discard');
      await tester.ensureVisible(discard);
      await tester.tap(discard);
      await tester.pumpAndSettle();

      // Discard clears the photos too, so this is the empty start state.
      expect(find.text('Save'), findsNothing);
      expect(find.text(PawScanCopy.takePhoto), findsOneWidget);
      expect(find.text('Which paw?'), findsNothing);
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
      expect(find.text('Save'), findsNothing);
      for (final level in PawAttentionLevel.values) {
        expect(
          find.text(formatPawAttentionLevel(level)),
          findsNothing,
          reason: 'a rejected scan must show no attention level',
        );
      }
    });

    testWidgets('an unreadable reply never reads as reassurance',
        (tester) async {
      // Caught on a real device: an undetermined level rendered the "No
      // result" card *and* "Nothing in these photos stood out." at the same
      // time — the exact false reassurance this feature exists to avoid.
      _useTallSurface(tester);
      final ai = _FakePawScanAiRepository()
        // `attentionLevel` defaults to undetermined — the state a failed
        // parse leaves behind.
        ..next =
            const PawScanDraft(status: PawScanDraftStatus.lowConfidenceReview);
      final picker = _FakePawPhotoPicker();
      await tester.pumpWidget(_app(ai: ai, picker: picker));
      await tester.pumpAndSettle();

      await _analyze(tester, picker);

      expect(find.text('Nothing in these photos stood out.'), findsNothing);
      expect(find.text('What Paw Scan can see'), findsNothing);
      expect(
        find.text(formatPawAttentionLevel(PawAttentionLevel.undetermined)),
        findsNothing,
      );
      // It is presented as a failed read, with a retake offered.
      expect(find.text('Could not read the result'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
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
      expect(find.text('Save'), findsNothing);
    });
  });

  group('capture', () {
    testWidgets('one tap on "Take a photo" opens the camera', (tester) async {
      // The whole point of this flow: no source-picker sheet between the
      // owner and the camera.
      final picker = _FakePawPhotoPicker()..next = _picked();
      await tester.pumpWidget(
        _app(ai: _FakePawScanAiRepository(), picker: picker),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(PawScanCopy.takePhoto));
      await tester.pumpAndSettle();

      expect(picker.pickCallCount, 1);
      expect(picker.lastSource, PawPhotoSource.camera);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('one tap on "Choose from gallery" opens the gallery',
        (tester) async {
      final picker = _FakePawPhotoPicker()..next = _picked();
      await tester.pumpWidget(
        _app(ai: _FakePawScanAiRepository(), picker: picker),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(PawScanCopy.chooseFromGallery));
      await tester.pumpAndSettle();

      expect(picker.pickCallCount, 1);
      expect(picker.lastSource, PawPhotoSource.gallery);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('the camera is the primary action before any photo',
        (tester) async {
      await tester.pumpWidget(_app(ai: _FakePawScanAiRepository()));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, PawScanCopy.takePhoto),
        findsOneWidget,
      );
      expect(find.textContaining('Describe'), findsNothing);
    });

    testWidgets('describing becomes primary once a photo exists',
        (tester) async {
      _useTallSurface(tester);
      final picker = _FakePawPhotoPicker();
      await tester.pumpWidget(
        _app(ai: _FakePawScanAiRepository(), picker: picker),
      );
      await tester.pumpAndSettle();

      await _capture(tester, picker);

      expect(
        find.widgetWithText(FilledButton, 'Describe 1 photo'),
        findsOneWidget,
      );
      // The camera stays available, demoted.
      expect(
        find.widgetWithText(OutlinedButton, PawScanCopy.camera),
        findsOneWidget,
      );
    });

    testWidgets('the paw selector appears only once there is a photo',
        (tester) async {
      _useTallSurface(tester);
      final picker = _FakePawPhotoPicker();
      await tester.pumpWidget(
        _app(ai: _FakePawScanAiRepository(), picker: picker),
      );
      await tester.pumpAndSettle();

      // Before a photo, asking which paw is a question about nothing.
      expect(find.text('Which paw?'), findsNothing);
      expect(find.text(PawScanCopy.captureTips), findsOneWidget);

      await _capture(tester, picker);

      expect(find.text('Which paw?'), findsOneWidget);
      expect(
        find.text(formatPawLocation(PawLocation.frontLeft)),
        findsOneWidget,
      );
    });

    testWidgets('after a rejection the camera is primary again',
        (tester) async {
      // Describing the same rejected photos again cannot help.
      _useTallSurface(tester);
      final ai = _FakePawScanAiRepository()
        ..next = const PawScanDraft.unusable(
          photoQuality: PawScanPhotoQuality.blurry,
        );
      final picker = _FakePawPhotoPicker();
      await tester.pumpWidget(_app(ai: ai, picker: picker));
      await tester.pumpAndSettle();

      await _analyze(tester, picker);

      expect(
        find.widgetWithText(FilledButton, PawScanCopy.takeAnotherPhoto),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Describe 1 photo'),
        findsOneWidget,
      );
    });

    testWidgets('capture is disabled at the photo cap', (tester) async {
      _useTallSurface(tester);
      final picker = _FakePawPhotoPicker();
      await tester.pumpWidget(
        _app(ai: _FakePawScanAiRepository(), picker: picker),
      );
      await tester.pumpAndSettle();

      await _capture(tester, picker, count: kMaxPawScanPhotos);

      final camera = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, PawScanCopy.camera),
      );
      final gallery = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, PawScanCopy.gallery),
      );
      expect(camera.onPressed, isNull);
      expect(gallery.onPressed, isNull);
      expect(picker.pickCallCount, kMaxPawScanPhotos);
    });
  });

  group('history', () {
    testWidgets('shows an empty state with no checks', (tester) async {
      await tester.pumpWidget(_app(ai: _FakePawScanAiRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('No paw checks yet'), findsOneWidget);
    });

    testWidgets('a history tile with every action fits a narrow phone',
        (tester) async {
      // Caught on device: the chip plus the actions overflowed a Row by 13px,
      // clipping the delete button. Two checks of the same paw enable the
      // compare action too, so this is the widest the tile ever gets — and a
      // narrow surface with a large font scale is the worst case.
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakePawCheckRepository()
        ..checks = [
          _check(),
          _check(id: 'check-2', checkedAt: DateTime.utc(2026, 9, 6)),
        ];
      await tester.pumpWidget(
        _app(ai: _FakePawScanAiRepository(), repository: repository),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // A RenderFlex overflow surfaces as a thrown FlutterError.
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Delete this check'), findsWidgets);
      expect(find.text('Follow up'), findsWidgets);
    });

    testWidgets('lists saved checks with their attention level',
        (tester) async {
      final repository = _FakePawCheckRepository()..checks = [_check()];
      await tester.pumpWidget(
        _app(ai: _FakePawScanAiRepository(), repository: repository),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
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
  _FakePawCheckRepository([List<PawCheck>? seed])
      : checks = List.of(seed ?? const []);

  /// Behaves like a store rather than a fixed list: saving has to show up in
  /// the watched stream, or a test cannot see what the owner would see after
  /// saving.
  List<PawCheck> checks;
  final saved = <PawCheck>[];
  final _controller = StreamController<List<PawCheck>>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PawCheck>> watchChecks({
    required EntityId userId,
    required EntityId petId,
  }) async* {
    yield List.of(checks);
    yield* _controller.stream;
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
    saved.add(check);
    checks = [check, ...checks.where((other) => other.id != check.id)];
    _controller.add(List.of(checks));
  }

  @override
  Future<void> deleteCheck({
    required EntityId userId,
    required EntityId petId,
    required EntityId checkId,
  }) async {
    checks = checks.where((other) => other.id != checkId).toList();
    _controller.add(List.of(checks));
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
  PawPhotoSource? lastSource;
  int pickCallCount = 0;

  @override
  Future<PickedFile?> pick(PawPhotoSource source) async {
    pickCallCount++;
    lastSource = source;
    return next;
  }

  @override
  Future<List<PickedFile>> pickMultipleFromGallery() async =>
      pick(PawPhotoSource.gallery)
          .then((file) => file == null ? <PickedFile>[] : [file]);
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
