// Drives the real app through the Documents flow to verify the uploaded
// file is kept visible: thumbnail in the list, inline preview and an
// "Attached file" open action in the document view. The document's file URL
// is served by an in-test localhost HTTP server so the preview really
// renders. Run with the screenshot driver:
//
//   SCREENSHOT_DIR=build/verify_screenshots flutter drive \
//     --driver=test_driver/screenshots.dart \
//     --target=integration_test/documents_show_files_test.dart \
//     -d <simulator-udid>
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('documents keep the uploaded file visible and openable',
      (tester) async {
    // Serve a generated PNG so the stored file URL really renders.
    final pngBytes = await _makePng();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      request.response.headers.contentType = ContentType('image', 'png');
      request.response.add(pngBytes);
      await request.response.close();
    });
    final imageUrl = 'http://127.0.0.1:${server.port}/original.jpg';

    final documents = _FakeDocumentRepository([
      PetDocument(
        id: const EntityId('doc-1'),
        userId: const EntityId('local-anonymous-user'),
        petId: const EntityId('pet-1'),
        title: 'Scanned vaccination card',
        type: PetDocumentType.vaccinationCertificate,
        fileUrl: Uri.parse(imageUrl),
        storagePath:
            'users/local-anonymous-user/pets/pet-1/documents/doc-1/original.jpg',
        issueDate: DateOnly.fromDateTime(DateTime(2026, 1, 5)),
      ),
      PetDocument(
        id: const EntityId('doc-2'),
        userId: const EntityId('local-anonymous-user'),
        petId: const EntityId('pet-1'),
        title: 'Insurance policy',
        type: PetDocumentType.insurance,
        fileUrl: Uri.parse('https://example.com/policy.pdf'),
        storagePath:
            'users/local-anonymous-user/pets/pet-1/documents/doc-2/original.pdf',
      ),
    ]);
    final pets = _MemoryPetRepository([
      const Pet(
        id: EntityId('pet-1'),
        userId: EntityId('local-anonymous-user'),
        name: 'Rex',
        species: 'Dog',
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

    // Navigate: pet list -> profile -> Documents.
    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();

    // The list shows both documents; the image one with a thumbnail and its
    // issue date on the title row.
    expect(find.text('Scanned vaccination card'), findsOneWidget);
    expect(find.text('Insurance policy'), findsOneWidget);
    expect(
      find.text('Vaccination Certificate · Issued Jan 5, 2026'),
      findsOneWidget,
    );
    final imageTile = find.ancestor(
      of: find.text('Scanned vaccination card'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: imageTile, matching: find.byType(Image)),
      findsOneWidget,
    );
    await _settleImages(tester);
    await binding.takeScreenshot('01_documents_list_thumbnail');

    // Open the image document: inline preview + attached-file action.
    await tester.tap(find.text('Scanned vaccination card'));
    await tester.pumpAndSettle();
    expect(find.text('Attached file'), findsOneWidget);
    expect(find.text('JPG'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    await _settleImages(tester);
    await binding.takeScreenshot('02_document_image_preview');

    // Back to the list, open the PDF document: labeled file tile, no preview.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insurance policy'));
    await tester.pumpAndSettle();
    expect(find.text('Attached file'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    await binding.takeScreenshot('03_document_pdf_tile');
  });
}

/// Gives in-flight network images a moment to arrive and paints the result.
Future<void> _settleImages(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 400)),
  );
  await tester.pump();
}

Future<Uint8List> _makePng() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 200, 200),
    Paint()..color = const Color(0xFF2E7D32),
  );
  canvas.drawCircle(
    const Offset(100, 100),
    60,
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final image = await recorder.endRecording().toImage(200, 200);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

class _FakeDocumentRepository implements DocumentRepository {
  _FakeDocumentRepository(this.documents);

  final List<PetDocument> documents;

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PetDocument>> watchDocuments({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream.value(List.of(documents));

  @override
  Future<PetDocument?> getDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {
    for (final document in documents) {
      if (document.id == documentId) {
        return document;
      }
    }
    return null;
  }

  @override
  Future<void> saveDocument(PetDocument document) async {}

  @override
  Future<void> deleteDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {}
}

class _MemoryPetRepository implements PetRepository {
  _MemoryPetRepository(List<Pet> seed) : _pets = List.of(seed);

  final List<Pet> _pets;

  @override
  Future<void> initialize() async {}

  @override
  Future<Pet?> getPet({
    required EntityId userId,
    required EntityId petId,
  }) async {
    for (final pet in _pets) {
      if (pet.id == petId) {
        return pet;
      }
    }
    return null;
  }

  @override
  Future<void> savePet(Pet pet) async {
    _pets.removeWhere((existing) => existing.id == pet.id);
    _pets.add(pet);
  }

  @override
  Future<void> deletePet({
    required EntityId userId,
    required EntityId petId,
  }) async {
    _pets.removeWhere((existing) => existing.id == petId);
  }

  @override
  Stream<List<Pet>> watchPets(EntityId userId) => Stream.value(List.of(_pets));
}
