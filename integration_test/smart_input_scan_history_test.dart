// Verifies that attaching a file/photo from Smart Input and confirming the
// AI extraction saves the analysis to Smart Input's History (not only the
// document to Documents), and that the History entry shows the attached
// files. Run with the screenshot driver:
//
//   SCREENSHOT_DIR=build/verify_screenshots flutter drive \
//     --driver=test_driver/screenshots.dart \
//     --target=integration_test/smart_input_scan_history_test.dart \
//     -d <simulator-udid>
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_page.dart';
import 'package:paw_vault/features/document_extraction/domain/repositories/document_extraction_ai_repository.dart';
import 'package:paw_vault/features/document_extraction/domain/services/document_source_picker.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/documents/presentation/widgets/attachment_views.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';

import 'support/fakes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('confirming a scanned document saves the analysis to History',
      (tester) async {
    final smartInput = _MemorySmartInputRepository();
    final base = AppDependencies.localFirst();
    final dependencies = AppDependencies(
      authRepository: base.authRepository,
      storageRepository: base.storageRepository,
      petRepository: FakePetRepository(const [
        Pet(
          id: EntityId('pet-1'),
          userId: EntityId('local-anonymous-user'),
          name: 'Rex',
        ),
      ]),
      timelineRepository: base.timelineRepository,
      documentRepository: base.documentRepository,
      reminderRepository: base.reminderRepository,
      aiRepository: base.aiRepository,
      smartInputRepository: smartInput,
      vetSummaryExportRepository: base.vetSummaryExportRepository,
      filePicker: base.filePicker,
      documentFileOpener: base.documentFileOpener,
      documentExtractionAiRepository: _FakeExtractionAiRepository(),
      documentSourcePicker: _FakeDocumentSourcePicker(),
      petPhotoPicker: base.petPhotoPicker,
      eventPhotoPicker: base.eventPhotoPicker,
      reminderNotificationScheduler: base.reminderNotificationScheduler,
      analyticsService: base.analyticsService,
      subscriptionService: base.subscriptionService,
      paywallPresenter: base.paywallPresenter,
      trackingAuthorizationService: base.trackingAuthorizationService,
      accountDeletionService: base.accountDeletionService,
    );

    await tester.pumpWidget(PawVaultApp(dependencies: dependencies));
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    // Navigate: pet list -> profile -> Smart Input -> attach a photo.
    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    final smartInputTile = find.text('Smart Input');
    await tester.ensureVisible(smartInputTile);
    await tester.tap(smartInputTile);
    await tester.pumpAndSettle();
    final attach = find.text('Attach document or photo');
    await tester.ensureVisible(attach);
    await tester.tap(attach);
    await tester.pumpAndSettle();

    // Pick from the gallery; the fake picker returns a photo and the fake AI
    // pre-fills the review form.
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    expect(find.text('Rabies vaccination'), findsOneWidget);
    await binding.takeScreenshot('01_scan_review_prefilled');

    // Confirm & save — this must save the document AND the History entry.
    final confirm = find.text('Confirm & save');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    // Back on Smart Input, the analysis is in History.
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Scanned document: Rabies vaccination'),
      findsOneWidget,
    );
    await binding.takeScreenshot('02_scan_analysis_in_history');

    final saved = smartInput.messages.single;
    expect(saved.status, SmartMessageStatus.confirmed);
    expect(saved.extractedData['title'], 'Rabies vaccination');
    // The reported bug: the attached photo appeared nowhere in History.
    expect(saved.attachments, hasLength(1));

    final tile = find.byKey(ValueKey('smart-message-${saved.id.value}'));
    expect(tile, findsOneWidget);
    // The paperclip, not the thumbnail: local-first storage hands out a
    // relative URI that never resolves, so asserting on a loaded image here
    // would only be testing the fake.
    expect(
      find.descendant(of: tile, matching: find.byIcon(Icons.attach_file)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile, matching: find.text('1 file')),
      findsOneWidget,
    );
    // The leading slot always holds something: the photo's thumbnail, or the
    // glyph standing in while it loads or if it cannot be loaded at all.
    expect(
      find.descendant(
        of: tile,
        matching: find.byType(AttachmentThumbnail),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile, matching: find.byIcon(Icons.auto_awesome)),
      findsOneWidget,
    );

    // Opening the entry shows a preview of the file, not just the text.
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.text('Attached file'), findsOneWidget);
    await binding.takeScreenshot('03_scan_history_details_attachment');
  });

  testWidgets('a scan with no readable date says which field is missing',
      (tester) async {
    // Issue date is required. When the scan cannot read one, confirming used
    // to show only "Please fix validation errors", with nothing on the form
    // to say what was wrong.
    final smartInput = _MemorySmartInputRepository();
    final base = AppDependencies.localFirst();
    final dependencies = AppDependencies(
      authRepository: base.authRepository,
      storageRepository: base.storageRepository,
      petRepository: FakePetRepository(const [
        Pet(
          id: EntityId('pet-1'),
          userId: EntityId('local-anonymous-user'),
          name: 'Rex',
        ),
      ]),
      timelineRepository: base.timelineRepository,
      documentRepository: base.documentRepository,
      reminderRepository: base.reminderRepository,
      aiRepository: base.aiRepository,
      smartInputRepository: smartInput,
      vetSummaryExportRepository: base.vetSummaryExportRepository,
      filePicker: base.filePicker,
      documentFileOpener: base.documentFileOpener,
      documentExtractionAiRepository:
          _FakeExtractionAiRepository(detectsIssueDate: false),
      documentSourcePicker: _FakeDocumentSourcePicker(),
      petPhotoPicker: base.petPhotoPicker,
      eventPhotoPicker: base.eventPhotoPicker,
      reminderNotificationScheduler: base.reminderNotificationScheduler,
      analyticsService: base.analyticsService,
      subscriptionService: base.subscriptionService,
      paywallPresenter: base.paywallPresenter,
      trackingAuthorizationService: base.trackingAuthorizationService,
      accountDeletionService: base.accountDeletionService,
    );

    await tester.pumpWidget(PawVaultApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    final smartInputTile = find.text('Smart Input');
    await tester.ensureVisible(smartInputTile);
    await tester.tap(smartInputTile);
    await tester.pumpAndSettle();
    final attach = find.text('Attach document or photo');
    await tester.ensureVisible(attach);
    await tester.tap(attach);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    // The form says the date is required and has none to show.
    expect(find.text('Issue date (required)'), findsOneWidget);
    expect(find.text('Not set'), findsWidgets);

    final confirm = find.text('Confirm & save');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    // Nothing was saved, and the row itself now names the problem — in the
    // error colour, so it reads as the required field it is.
    expect(find.text('Issue date is required'), findsOneWidget);
    expect(smartInput.messages, isEmpty);

    final errorColor = Theme.of(
      tester.element(find.text('Issue date is required')),
    ).colorScheme.error;
    for (final label in ['Issue date (required)', 'Issue date is required']) {
      expect(
        tester.widget<Text>(find.text(label)).style?.color,
        errorColor,
        reason: '"$label" should be shown in the error colour',
      );
    }

    // Picking a date clears it again.
    await tester.tap(find.text('Issue date (required)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Issue date is required'), findsNothing);
  });

  testWidgets('the review form shows the files attached to the analysis',
      (tester) async {
    // Asked for by QA: before saving, you may have forgotten which photo you
    // attached, so the form has to show it rather than only counting pages.
    final base = AppDependencies.localFirst();
    final dependencies = AppDependencies(
      authRepository: base.authRepository,
      storageRepository: base.storageRepository,
      petRepository: FakePetRepository(const [
        Pet(
          id: EntityId('pet-1'),
          userId: EntityId('local-anonymous-user'),
          name: 'Rex',
        ),
      ]),
      timelineRepository: base.timelineRepository,
      documentRepository: base.documentRepository,
      reminderRepository: base.reminderRepository,
      aiRepository: base.aiRepository,
      smartInputRepository: _MemorySmartInputRepository(),
      vetSummaryExportRepository: base.vetSummaryExportRepository,
      filePicker: base.filePicker,
      documentFileOpener: base.documentFileOpener,
      documentExtractionAiRepository: _FakeExtractionAiRepository(),
      documentSourcePicker: _FakeDocumentSourcePicker(),
      petPhotoPicker: base.petPhotoPicker,
      eventPhotoPicker: base.eventPhotoPicker,
      reminderNotificationScheduler: base.reminderNotificationScheduler,
      analyticsService: base.analyticsService,
      subscriptionService: base.subscriptionService,
      paywallPresenter: base.paywallPresenter,
      trackingAuthorizationService: base.trackingAuthorizationService,
      accountDeletionService: base.accountDeletionService,
    );

    await tester.pumpWidget(PawVaultApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    final smartInputTile = find.text('Smart Input');
    await tester.ensureVisible(smartInputTile);
    await tester.tap(smartInputTile);
    await tester.pumpAndSettle();
    final attach = find.text('Attach document or photo');
    await tester.ensureVisible(attach);
    await tester.tap(attach);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    // One page picked, one thumbnail of it on the review form.
    expect(find.text('1 page attached'), findsOneWidget);
    expect(_thumbnails(), findsOneWidget);

    // A second page gets its own thumbnail.
    final addPage = find.text('Add page');
    await tester.ensureVisible(addPage);
    await tester.tap(addPage);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(find.text('2 pages attached'), findsOneWidget);
    expect(_thumbnails(), findsNWidgets(2));

    // Tapping one opens it full screen, so the photo can be checked before
    // anything is saved.
    await tester.tap(_thumbnails().first);
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('a scanned expiry date can be removed again', (tester) async {
    // Expiry stays optional: the scan fills it in when the document says so,
    // and a wrong one has to be removable since there is nothing to fall
    // back to.
    final base = AppDependencies.localFirst();
    final dependencies = AppDependencies(
      authRepository: base.authRepository,
      storageRepository: base.storageRepository,
      petRepository: FakePetRepository(const [
        Pet(
          id: EntityId('pet-1'),
          userId: EntityId('local-anonymous-user'),
          name: 'Rex',
        ),
      ]),
      timelineRepository: base.timelineRepository,
      documentRepository: base.documentRepository,
      reminderRepository: base.reminderRepository,
      aiRepository: base.aiRepository,
      smartInputRepository: _MemorySmartInputRepository(),
      vetSummaryExportRepository: base.vetSummaryExportRepository,
      filePicker: base.filePicker,
      documentFileOpener: base.documentFileOpener,
      documentExtractionAiRepository:
          _FakeExtractionAiRepository(detectsExpiryDate: true),
      documentSourcePicker: _FakeDocumentSourcePicker(),
      petPhotoPicker: base.petPhotoPicker,
      eventPhotoPicker: base.eventPhotoPicker,
      reminderNotificationScheduler: base.reminderNotificationScheduler,
      analyticsService: base.analyticsService,
      subscriptionService: base.subscriptionService,
      paywallPresenter: base.paywallPresenter,
      trackingAuthorizationService: base.trackingAuthorizationService,
      accountDeletionService: base.accountDeletionService,
    );

    await tester.pumpWidget(PawVaultApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    final smartInputTile = find.text('Smart Input');
    await tester.ensureVisible(smartInputTile);
    await tester.tap(smartInputTile);
    await tester.pumpAndSettle();
    final attach = find.text('Attach document or photo');
    await tester.ensureVisible(attach);
    await tester.tap(attach);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    // The scan read one off the document, so it is filled in.
    expect(find.text('July 1, 2027'), findsOneWidget);

    final clear = find.byTooltip('Clear expiry date');
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();

    expect(find.text('July 1, 2027'), findsNothing);
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Expiry date (optional)'),
        matching: find.text('Not set'),
      ),
      findsOneWidget,
    );
    // Removing it leaves nothing to clear.
    expect(find.byTooltip('Clear expiry date'), findsNothing);
  });
}

/// The review form's attachment thumbnails, which are `Image.memory` widgets
/// reading the picked bytes.
Finder _thumbnails() => find.descendant(
      of: find.byType(InkWell),
      matching: find.byType(Image),
    );

class _FakeDocumentSourcePicker implements DocumentSourcePicker {
  /// A real 1x1 PNG, not placeholder bytes: the review form decodes what was
  /// picked to show a thumbnail, so junk bytes would only ever exercise the
  /// error placeholder.
  static final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMB'
    'AQDJ/pLvAAAAAElFTkSuQmCC',
  );

  @override
  Future<PickedFile?> pick(DocumentSource source) async {
    return PickedFile(
      bytes: _png,
      fileName: 'scan.png',
      extension: 'png',
      contentType: 'image/png',
    );
  }

  @override
  Future<List<PickedFile>> pickMultipleFromGallery() async =>
      pick(DocumentSource.gallery)
          .then((file) => file == null ? <PickedFile>[] : [file]);
}

class _FakeExtractionAiRepository implements DocumentExtractionAiRepository {
  _FakeExtractionAiRepository({
    this.detectsIssueDate = true,
    this.detectsExpiryDate = false,
  });

  /// A real scan often cannot read a date off the page, and the date is
  /// required — so the review form has to handle a draft without one.
  final bool detectsIssueDate;

  /// Whether the document carried wording like "valid until". Most do not,
  /// so the draft leaves the field empty by default.
  final bool detectsExpiryDate;

  @override
  Future<DocumentExtractionDraft> extractDocument({
    required List<DocumentPage> pages,
  }) async {
    return DocumentExtractionDraft(
      requiresConfirmation: true,
      detectedType: PetDocumentType.vaccinationCertificate,
      title: 'Rabies vaccination',
      issueDate: detectsIssueDate
          ? const DateOnly(year: 2026, month: 7, day: 1)
          : null,
      expiryDate: detectsExpiryDate
          ? const DateOnly(year: 2027, month: 7, day: 1)
          : null,
      confidence: 0.9,
    );
  }
}

class _MemorySmartInputRepository implements SmartInputRepository {
  final messages = <SmartMessage>[];
  final _controller = StreamController<List<SmartMessage>>.broadcast();

  @override
  Future<SmartInputDraft> createDraft(String input) async =>
      SmartInputDraft(originalText: input, requiresConfirmation: true);

  @override
  Future<void> saveSmartMessage(SmartMessage message) async {
    messages.removeWhere((existing) => existing.id == message.id);
    messages.add(message);
    _controller.add(List.of(messages));
  }

  @override
  Future<SmartMessage?> getSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async {
    for (final message in messages) {
      if (message.id == messageId) {
        return message;
      }
    }
    return null;
  }

  @override
  Future<void> deleteSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async {
    messages.removeWhere((existing) => existing.id == messageId);
    _controller.add(List.of(messages));
  }

  @override
  Stream<List<SmartMessage>> watchSmartMessages({
    required EntityId userId,
    required EntityId petId,
  }) async* {
    yield List.of(messages);
    yield* _controller.stream;
  }
}
