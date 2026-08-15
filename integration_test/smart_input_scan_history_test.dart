// Verifies that attaching a file/photo from Smart Input and confirming the
// AI extraction saves the analysis to Smart Input's History (not only the
// document to Documents). Run with the screenshot driver:
//
//   SCREENSHOT_DIR=build/verify_screenshots flutter drive \
//     --driver=test_driver/screenshots.dart \
//     --target=integration_test/smart_input_scan_history_test.dart \
//     -d <simulator-udid>
import 'dart:async';
import 'dart:typed_data';

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
  });
}

class _FakeDocumentSourcePicker implements DocumentSourcePicker {
  @override
  Future<PickedFile?> pick(DocumentSource source) async {
    return PickedFile(
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'scan.jpg',
      extension: 'jpg',
      contentType: 'image/jpeg',
    );
  }
}

class _FakeExtractionAiRepository implements DocumentExtractionAiRepository {
  @override
  Future<DocumentExtractionDraft> extractDocument({
    required List<DocumentPage> pages,
  }) async {
    return const DocumentExtractionDraft(
      requiresConfirmation: true,
      detectedType: PetDocumentType.vaccinationCertificate,
      title: 'Rabies vaccination',
      issueDate: DateOnly(year: 2026, month: 7, day: 1),
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
