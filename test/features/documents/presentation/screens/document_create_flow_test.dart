// Drives the full create flow headlessly through the real app shell:
// pet list -> profile -> Documents -> Add document -> save WITHOUT a file.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';

void main() {
  testWidgets('shows a visible loading overlay while saving', (tester) async {
    final documents = _SlowSaveDocumentRepository();
    await tester.pumpWidget(
      PawVaultApp(dependencies: _dependencies(documents)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add document'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passport').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'EU Pet Passport',
    );
    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.tap(save);
    while (!documents.saveStarted.isCompleted) {
      await tester.pump();
    }
    await tester.pump();

    expect(find.text('Saving…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    documents.completeSave();
    await tester.pumpAndSettle();
    expect(find.text('Saving…'), findsNothing);
    expect(find.text('Document saved'), findsOneWidget);
  });

  testWidgets('a document can be saved without attaching a file',
      (tester) async {
    final documents = _MemoryDocumentRepository();

    await tester.pumpWidget(
      PawVaultApp(dependencies: _dependencies(documents)),
    );
    await tester.pumpAndSettle();

    // Navigate: pet list -> profile -> Documents -> Add document.
    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add document'));
    await tester.pumpAndSettle();

    // The file attachment is optional and the save button is plain "Save".
    expect(find.text('Attach photo or file (optional)'), findsOneWidget);
    expect(find.text('Pick file & save'), findsNothing);

    // Fill the required fields and save without attaching anything.
    await tester.tap(find.text('Type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insurance').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Liability insurance',
    );
    final saveButton = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Saved without a file and visible in the documents list.
    final saved = documents.savedDocument;
    expect(saved, isNotNull);
    expect(saved!.title, 'Liability insurance');
    expect(saved.fileUrl, isNull);
    expect(saved.storagePath, isNull);
    expect(find.text('Liability insurance'), findsOneWidget);
  });
}

AppDependencies _dependencies(DocumentRepository documents) {
  final pets = _FakePetRepository(const [
    Pet(
      id: EntityId('pet-1'),
      userId: EntityId('local-anonymous-user'),
      name: 'Rex',
    ),
  ]);
  final base = AppDependencies.localFirst();
  return AppDependencies(
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
    eventPhotoPicker: base.eventPhotoPicker,
    reminderNotificationScheduler: base.reminderNotificationScheduler,
    analyticsService: base.analyticsService,
    subscriptionService: base.subscriptionService,
    paywallPresenter: base.paywallPresenter,
    trackingAuthorizationService: base.trackingAuthorizationService,
    accountDeletionService: base.accountDeletionService,
  );
}

class _SlowSaveDocumentRepository extends _MemoryDocumentRepository {
  final saveStarted = Completer<void>();
  final _saveGate = Completer<void>();

  void completeSave() => _saveGate.complete();

  @override
  Future<void> saveDocument(PetDocument document) async {
    saveStarted.complete();
    await _saveGate.future;
    await super.saveDocument(document);
  }
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
