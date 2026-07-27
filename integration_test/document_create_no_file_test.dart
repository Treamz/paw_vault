// Drives the real app through creating a document WITHOUT attaching a file,
// capturing verification screenshots. Run with the screenshot driver:
//
//   SCREENSHOT_DIR=build/verify_screenshots flutter drive \
//     --driver=test_driver/screenshots.dart \
//     --target=integration_test/document_create_no_file_test.dart \
//     -d <simulator-udid>
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a document is saved without a file attachment', (tester) async {
    final documents = _MemoryDocumentRepository();
    final pets = _FakePetRepository(const [
      Pet(
        id: EntityId('pet-1'),
        userId: EntityId('local-anonymous-user'),
        name: 'Rex',
      ),
    ]);
    final base = AppDependencies.localFirst();
    final dependencies = AppDependencies(
      authRepository: base.authRepository,
      storageRepository: base.storageRepository,
      petRepository: pets,
      timelineRepository: base.timelineRepository,
      documentRepository: documents,
      reminderRepository: base.reminderRepository,
      aiRepository: base.aiRepository,
      smartInputRepository: base.smartInputRepository,
      vetSummaryExportRepository: base.vetSummaryExportRepository,
      filePicker: base.filePicker,
      documentFileOpener: base.documentFileOpener,
      documentExtractionAiRepository: base.documentExtractionAiRepository,
      documentSourcePicker: base.documentSourcePicker,
      petPhotoPicker: base.petPhotoPicker,
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

    // Navigate: pet list -> profile -> Documents -> Add document.
    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add document'));
    await tester.pumpAndSettle();

    // Attachment is optional; the save button no longer forces a file pick.
    expect(find.text('Attach file (optional)'), findsOneWidget);
    expect(find.text('Pick file & save'), findsNothing);

    // Fill the required fields.
    await tester.tap(find.text('Type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insurance').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Liability insurance',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('01_add_document_no_file_form');

    // Save without attaching anything.
    final saveButton = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final saved = documents.savedDocument;
    expect(saved, isNotNull);
    expect(saved!.fileUrl, isNull);
    expect(saved.storagePath, isNull);
    expect(find.text('Liability insurance'), findsOneWidget);
    await binding.takeScreenshot('02_documents_list_saved_no_file');
  });
}

class _MemoryDocumentRepository implements DocumentRepository {
  final _documents = <PetDocument>[];
  final _controller = StreamController<List<PetDocument>>.broadcast();

  PetDocument? get savedDocument => _documents.isEmpty ? null : _documents.last;

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PetDocument>> watchDocuments({
    required EntityId userId,
    required EntityId petId,
  }) async* {
    yield List.of(_documents);
    yield* _controller.stream;
  }

  @override
  Future<PetDocument?> getDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {
    for (final document in _documents) {
      if (document.id == documentId) {
        return document;
      }
    }
    return null;
  }

  @override
  Future<void> saveDocument(PetDocument document) async {
    _documents.removeWhere((existing) => existing.id == document.id);
    _documents.add(document);
    _controller.add(List.of(_documents));
  }

  @override
  Future<void> deleteDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {
    _documents.removeWhere((existing) => existing.id == documentId);
    _controller.add(List.of(_documents));
  }
}

class _FakePetRepository implements PetRepository {
  _FakePetRepository(this.pets);

  final List<Pet> pets;

  @override
  Future<void> initialize() async {}

  @override
  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  }) async {
    for (final pet in pets) {
      if (pet.id == petId) {
        return pet;
      }
    }
    return null;
  }

  @override
  Future<void> savePet(Pet pet) async {}

  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) async {}

  @override
  Stream<List<Pet>> watchPets(EntityId userId) => Stream<List<Pet>>.value(pets);
}
