// Verifies QA batch 8's visible changes: timeline tiles show the linked
// reminder date and sort newest-first, document tiles open a read-only
// detail sheet with an explicit Edit action plus a sort menu, the document
// form requires an issue date, and Smart Input history shows the saved
// date with a delete action. Run with the screenshot driver:
//
//   SCREENSHOT_DIR=build/verify_screenshots flutter drive \
//     --driver=test_driver/screenshots.dart \
//     --target=integration_test/qa_batch8_test.dart \
//     -d <simulator-udid>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';

import 'support/fakes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const userId = EntityId('local-anonymous-user');
  const petId = EntityId('pet-1');

  AppDependencies dependencies() {
    final base = AppDependencies.localFirst();
    return AppDependencies(
      authRepository: base.authRepository,
      storageRepository: base.storageRepository,
      petRepository: FakePetRepository(const [
        Pet(id: petId, userId: userId, name: 'Rex'),
      ]),
      timelineRepository: FakeTimelineRepository([
        PetEvent(
          id: const EntityId('event-older'),
          userId: userId,
          petId: petId,
          type: PetEventType.vetVisit,
          title: 'Annual checkup',
          date: UtcDateTime(DateTime.utc(2026, 7, 10)),
          source: PetEventSource.manual,
          createdAt: UtcDateTime(DateTime.utc(2026, 7, 10, 9)),
        ),
        PetEvent(
          id: const EntityId('event-newer'),
          userId: userId,
          petId: petId,
          type: PetEventType.vaccination,
          title: 'Rabies vaccination',
          date: UtcDateTime(DateTime.utc(2026, 7, 20)),
          source: PetEventSource.manual,
          nextReminderDate: UtcDateTime(DateTime.utc(2026, 8, 30, 12)),
          createdAt: UtcDateTime(DateTime.utc(2026, 7, 20, 9)),
        ),
      ]),
      documentRepository: FakeDocumentRepository([
        PetDocument(
          id: const EntityId('doc-1'),
          userId: userId,
          petId: petId,
          title: 'EU Pet Passport',
          type: PetDocumentType.passport,
          issueDate: const DateOnly(year: 2024, month: 3, day: 5),
          notes: 'Issued in Vienna',
          createdAt: UtcDateTime(DateTime.utc(2026, 7)),
        ),
        PetDocument(
          id: const EntityId('doc-2'),
          userId: userId,
          petId: petId,
          title: 'Liability insurance',
          type: PetDocumentType.insurance,
          issueDate: const DateOnly(year: 2025, month: 1, day: 10),
          createdAt: UtcDateTime(DateTime.utc(2026, 7, 15)),
        ),
      ]),
      reminderRepository: base.reminderRepository,
      aiRepository: base.aiRepository,
      smartInputRepository: FakeSmartInputRepository([
        SmartMessage(
          id: const EntityId('msg-1'),
          userId: userId,
          petId: petId,
          originalText: 'Bella got her rabies shot today.',
          detectedIntent: SmartMessageIntent.addVaccination,
          suggestedActions: const [
            SmartSuggestedAction(
              type: SmartSuggestedActionType.createTimelineEvent,
            ),
          ],
          confidence: 0.9,
          status: SmartMessageStatus.confirmed,
          createdAt: UtcDateTime(DateTime.utc(2026, 7, 25, 14, 30)),
        ),
      ]),
      vetSummaryExportRepository: base.vetSummaryExportRepository,
      filePicker: base.filePicker,
      documentFileOpener: base.documentFileOpener,
      documentExtractionAiRepository: base.documentExtractionAiRepository,
      documentSourcePicker: base.documentSourcePicker,
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

  testWidgets('timeline shows reminder dates and documents open read-only',
      (tester) async {
    await tester.pumpWidget(PawVaultApp(dependencies: dependencies()));
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    // Navigate: pet list -> profile -> Timeline.
    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    final timelineTile = find.text('Timeline');
    await tester.ensureVisible(timelineTile);
    await tester.tap(timelineTile);
    await tester.pumpAndSettle();

    // Newest event first, and its tile carries the reminder date.
    final tiles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title as Text?)?.data)
        .toList();
    expect(tiles.first, 'Rabies vaccination');
    expect(find.textContaining('Reminder Aug 30, 2026'), findsOneWidget);
    await binding.takeScreenshot('01_timeline_reminder_date');

    // Back to profile, open Documents.
    await tester.pageBack();
    await tester.pumpAndSettle();
    final documentsTile = find.text('Documents');
    await tester.ensureVisible(documentsTile);
    await tester.tap(documentsTile);
    await tester.pumpAndSettle();

    // Sort menu offers date and type ordering.
    await tester.tap(find.byTooltip('Sort documents'));
    await tester.pumpAndSettle();
    expect(find.text('Newest first'), findsOneWidget);
    expect(find.text('By type'), findsOneWidget);
    await binding.takeScreenshot('02_documents_sort_menu');
    await tester.tap(find.text('By type'));
    await tester.pumpAndSettle();

    // Tapping a document opens the read-only detail sheet, not the editor.
    await tester.tap(find.text('EU Pet Passport'));
    await tester.pumpAndSettle();
    expect(find.text('Issued in Vienna'), findsOneWidget);
    final editButton = find.text('Edit document');
    expect(editButton, findsOneWidget);
    await binding.takeScreenshot('03_document_readonly_details');

    // Editing is an explicit action from the sheet.
    await tester.ensureVisible(editButton);
    await tester.tap(editButton);
    await tester.pumpAndSettle();
    expect(find.text('Edit Document'), findsOneWidget);
  });

  testWidgets('document form requires an issue date', (tester) async {
    await tester.pumpWidget(PawVaultApp(dependencies: dependencies()));
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    final documentsTile = find.text('Documents');
    await tester.ensureVisible(documentsTile);
    await tester.tap(documentsTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add document'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passport').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'New passport',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Issue date is required'), findsOneWidget);
    await binding.takeScreenshot('04_document_issue_date_required');
  });

  testWidgets('smart input history shows saved date and delete action',
      (tester) async {
    await tester.pumpWidget(PawVaultApp(dependencies: dependencies()));
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    final smartInputTile = find.text('Smart Input');
    await tester.ensureVisible(smartInputTile);
    await tester.tap(smartInputTile);
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Bella got her rabies shot today.'), findsOneWidget);
    // The tile shows when the analysis was saved, plus a delete action.
    expect(find.textContaining('Jul 25, 2026'), findsOneWidget);
    expect(find.byTooltip('Delete analysis'), findsOneWidget);
    await binding.takeScreenshot('05_smart_input_history_date_delete');

    // Suggested actions in the detail sheet are tappable: the chip opens a
    // pre-filled Add Event form so the user creates the event themselves.
    await tester.tap(find.text('Bella got her rabies shot today.'));
    await tester.pumpAndSettle();
    final actionChip = find.widgetWithText(ActionChip, 'Create timeline event');
    expect(actionChip, findsOneWidget);
    await binding.takeScreenshot('06_history_suggested_action_chip');
    await tester.tap(actionChip);
    await tester.pumpAndSettle();
    expect(find.text('Add Event'), findsWidgets);
    expect(
      find.widgetWithText(TextFormField, 'Bella got her rabies shot today.'),
      findsWidgets,
    );
    await binding.takeScreenshot('07_history_action_opens_event_form');
  });
}
