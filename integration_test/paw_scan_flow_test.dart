// Drives the real app through the Paw Scan flow: capture, describe, the
// non-diagnostic notice, confirming a check into the journal, and the
// rejection path where a non-paw photo yields no verdict at all. The AI and
// camera boundaries are faked. Run with the screenshot driver:
//
//   SCREENSHOT_DIR=build/verify_screenshots flutter drive \
//     --driver=test_driver/screenshots.dart \
//     --target=integration_test/paw_scan_flow_test.dart \
//     -d <simulator-udid>
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_observation.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_scan_draft.dart';
import 'package:paw_vault/features/paw_scan/domain/paw_scan_copy.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';

import 'support/fakes.dart';

final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8AAAwAB/AF+0B0a'
  'AAAAAElFTkSuQmCC',
);

PickedFile _pawPhoto() => PickedFile(
      bytes: Uint8List.fromList(_pngBytes),
      fileName: 'paw.png',
      extension: 'png',
      contentType: 'image/png',
    );

AppDependencies _dependencies({
  required PawScanDraft draft,
  required FakePawCheckRepository pawChecks,
  required PetRepository pets,
}) {
  final base = AppDependencies.localFirst();

  return AppDependencies(
    authRepository: base.authRepository,
    storageRepository: base.storageRepository,
    petRepository: pets,
    timelineRepository: base.timelineRepository,
    documentRepository: base.documentRepository,
    reminderRepository: base.reminderRepository,
    aiRepository: base.aiRepository,
    smartInputRepository: base.smartInputRepository,
    vetSummaryExportRepository: base.vetSummaryExportRepository,
    filePicker: base.filePicker,
    documentFileOpener: base.documentFileOpener,
    documentExtractionAiRepository: base.documentExtractionAiRepository,
    documentSourcePicker: base.documentSourcePicker,
    pawCheckRepository: pawChecks,
    pawScanAiRepository: FakePawScanAiRepository(draft),
    pawPhotoPicker: FakePawPhotoPicker(_pawPhoto()),
    petPhotoPicker: base.petPhotoPicker,
    eventPhotoPicker: base.eventPhotoPicker,
    reminderNotificationScheduler: base.reminderNotificationScheduler,
    analyticsService: base.analyticsService,
    subscriptionService: base.subscriptionService,
    paywallPresenter: base.paywallPresenter,
    trackingAuthorizationService: base.trackingAuthorizationService,
    accountDeletionService: base.accountDeletionService,
  );
}

PetRepository _pets() => FakePetRepository(const [
      Pet(
        id: EntityId('pet-1'),
        userId: EntityId('local-anonymous-user'),
        name: 'Rex',
        species: 'dog',
      ),
    ]);

/// Pet list -> profile -> Paw Scan.
Future<void> _openPawScan(WidgetTester tester) async {
  await tester.tap(find.text('Rex'));
  await tester.pumpAndSettle();
  final tile = find.text('Paw Scan');
  await tester.ensureVisible(tile);
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

Future<void> _captureAndDescribe(WidgetTester tester) async {
  // One tap to the camera — no source-picker sheet in between.
  final takePhoto = find.text(PawScanCopy.takePhoto);
  await tester.ensureVisible(takePhoto);
  await tester.tap(takePhoto);
  await tester.pumpAndSettle();

  final describe = find.textContaining('Describe');
  await tester.ensureVisible(describe);
  await tester.tap(describe);
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a described paw check is saved only on confirm', (tester) async {
    final pawChecks = FakePawCheckRepository();
    await tester.pumpWidget(
      PawVaultApp(
        dependencies: _dependencies(
          draft: const PawScanDraft(
            observations: [
              PawObservation(
                area: PawObservationArea.pad,
                text: 'A dark area near the centre of the main pad.',
              ),
            ],
            attentionLevel: PawAttentionLevel.vetSoon,
            summary: 'One pad looks different from the others.',
            confidence: 0.84,
          ),
          pawChecks: pawChecks,
          pets: _pets(),
        ),
      ),
    );
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    await _openPawScan(tester);

    // The notice is there before anything is captured.
    expect(find.text(PawScanCopy.disclaimerTitle), findsWidgets);

    await _captureAndDescribe(tester);

    expect(find.text('Worth showing a vet soon'), findsOneWidget);
    expect(
      find.textContaining('A dark area near the centre of the main pad.'),
      findsOneWidget,
    );
    expect(find.text(PawScanCopy.nothingSavedYet), findsOneWidget);
    await binding.takeScreenshot('01_paw_scan_result');

    // Nothing is written during review.
    expect(pawChecks.checks, isEmpty);

    final note = find.widgetWithText(
      TextField,
      'Anything you noticed yourself? (optional)',
    );
    await tester.ensureVisible(note);
    await tester.enterText(note, 'She was licking it last night.');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final log = find.widgetWithText(FilledButton, 'Log this check');
    await tester.ensureVisible(log);
    await tester.tap(log);
    await tester.pumpAndSettle();

    expect(pawChecks.checks, hasLength(1));
    final saved = pawChecks.checks.single;
    expect(saved.attentionLevel, PawAttentionLevel.vetSoon);
    expect(saved.ownerNote, 'She was licking it last night.');
    expect(saved.observations, hasLength(1));
    // Opt-in: the owner did not switch it on.
    expect(saved.includeInVetSummary, isFalse);
    expect(find.text('Paw check saved to the journal'), findsOneWidget);

    // The check appears in the journal.
    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();
    expect(find.text('Worth showing a vet soon'), findsOneWidget);
    expect(
      find.textContaining('A dark area near the centre of the main pad.'),
      findsOneWidget,
    );
    await binding.takeScreenshot('02_paw_scan_journal');
  });

  testWidgets('a discarded result writes nothing', (tester) async {
    final pawChecks = FakePawCheckRepository();
    await tester.pumpWidget(
      PawVaultApp(
        dependencies: _dependencies(
          draft: const PawScanDraft(
            observations: [
              PawObservation(
                area: PawObservationArea.pad,
                text: 'A dark area on the pad.',
              ),
            ],
            attentionLevel: PawAttentionLevel.monitor,
            confidence: 0.8,
          ),
          pawChecks: pawChecks,
          pets: _pets(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openPawScan(tester);
    await _captureAndDescribe(tester);

    final discard = find.widgetWithText(OutlinedButton, 'Discard');
    await tester.ensureVisible(discard);
    await tester.tap(discard);
    await tester.pumpAndSettle();

    expect(pawChecks.checks, isEmpty);
    expect(find.text('Keep an eye on it'), findsNothing);
  });

  testWidgets('a photo that is not a paw yields no attention level',
      (tester) async {
    final pawChecks = FakePawCheckRepository();
    await tester.pumpWidget(
      PawVaultApp(
        dependencies: _dependencies(
          draft: const PawScanDraft.unusable(
            photoQuality: PawScanPhotoQuality.notAPaw,
          ),
          pawChecks: pawChecks,
          pets: _pets(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openPawScan(tester);
    await _captureAndDescribe(tester);

    expect(find.text('That does not look like a paw'), findsOneWidget);
    expect(find.text('Log this check'), findsNothing);
    for (final level in PawAttentionLevel.values) {
      expect(
        find.text(formatPawAttentionLevel(level)),
        findsNothing,
        reason: 'a rejected scan must show no attention level',
      );
    }
    expect(pawChecks.checks, isEmpty);
  });
}
