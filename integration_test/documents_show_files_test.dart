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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paw_vault/app/app.dart';
import 'package:paw_vault/core/di/app_dependencies.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/entities/document_attachment.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/repositories/pet_repository.dart';

import 'support/fakes.dart';

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
      // Scanned from two pages: the reported bug showed only the first.
      PetDocument(
        id: const EntityId('doc-3'),
        userId: const EntityId('local-anonymous-user'),
        petId: const EntityId('pet-1'),
        title: 'Two-page lab result',
        type: PetDocumentType.labResult,
        attachments: [
          DocumentAttachment(
            fileUrl: Uri.parse('$imageUrl?page=1'),
            storagePath: 'users/local-anonymous-user/pets/pet-1/documents/'
                'doc-3/attachment_0.jpg',
          ),
          DocumentAttachment(
            fileUrl: Uri.parse('$imageUrl?page=2'),
            storagePath: 'users/local-anonymous-user/pets/pet-1/documents/'
                'doc-3/attachment_1.jpg',
          ),
        ],
        issueDate: DateOnly.fromDateTime(DateTime(2026, 2, 9)),
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
      reminderNotificationScheduler: FakeReminderNotificationScheduler(),
      analyticsService: base.analyticsService,
      subscriptionService: base.subscriptionService,
      paywallPresenter: base.paywallPresenter,
      trackingAuthorizationService: base.trackingAuthorizationService,
      accountDeletionService: base.accountDeletionService,
    );

    await tester.pumpWidget(PawVaultApp(dependencies: dependencies));
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    // `takeScreenshot` right after `pumpAndSettle` kept returning the same
    // frame for every call — all four PNGs came out byte-identical. The extra
    // `pump` forces the surface to update first, matching what the working
    // store-screenshot run in screenshots_test.dart does.
    Future<void> shoot(String name) async {
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 200));
      await binding.takeScreenshot(name);
    }

    // Navigate: pet list -> profile -> Documents.
    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();

    // The list shows both documents; the image one with a thumbnail and its
    // issue date on the title row.
    expect(find.text('Scanned vaccination card'), findsOneWidget);
    expect(find.text('Insurance policy'), findsOneWidget);
    // Both of these assertions were stale and had been failing on `main`
    // before this change: the subtitle lost its "Issued" prefix, and the list
    // row shows a type icon rather than a thumbnail (`_DocumentsContent`
    // renders a CircleAvatar — "the photo itself is visible inside the
    // document"). Integration tests do not run under `flutter test`, so
    // nobody noticed.
    expect(
      find.text('Vaccination Certificate · Jan 5, 2026'),
      findsOneWidget,
    );
    final imageTile = find.ancestor(
      of: find.text('Scanned vaccination card'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: imageTile, matching: find.byType(CircleAvatar)),
      findsOneWidget,
    );
    // Reported twice: opening a document showed a blank box for a couple of
    // seconds with no hint that anything was attached. The row now says so
    // without waiting on the network, and carries a thumbnail that warms the
    // cache the sheet reads from.
    expect(
      find.descendant(of: imageTile, matching: find.byIcon(Icons.attach_file)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: imageTile,
        matching: find.byType(CachedNetworkImage),
      ),
      findsOneWidget,
    );
    await _settleImages(tester);
    await shoot('01_documents_list');

    // Tapping a row opens the details sheet. Its attachment block is what
    // this fix changed, so assert against that rather than the form screen's
    // "Attached file" tile, which the old assertions were aimed at.
    await tester.tap(find.text('Scanned vaccination card'));
    await tester.pumpAndSettle();
    await _settleImages(tester);
    expect(find.text('Issued'), findsOneWidget);
    expect(_sheetImages(), findsOneWidget);
    // The preview declares a placeholder, so the sheet shows a loading box
    // the moment it opens instead of empty space. That ambiguity is what QA
    // reported as "you cannot even tell something is attached".
    expect(
      tester.widget<CachedNetworkImage>(_sheetImages()).placeholder,
      isNotNull,
    );
    await shoot('02_document_image_preview');

    // A non-image attachment gets an open action labelled with its type
    // instead of a preview. The sheet has to be dismissed first, or the tap
    // lands on its scrim.
    await _dismissSheet(tester);
    await tester.tap(find.text('Insurance policy'));
    await tester.pumpAndSettle();
    expect(find.text('Open PDF'), findsOneWidget);
    expect(_sheetImages(), findsNothing);
    await shoot('03_document_pdf_tile');

    // The scanned two-page document must show BOTH files. Showing one is the
    // bug QA reported: the second attachment looked lost.
    await _dismissSheet(tester);
    await tester.tap(find.text('Two-page lab result'));
    await tester.pumpAndSettle();
    await _settleImages(tester);

    expect(_sheetImages(), findsNWidgets(2));
    await shoot('04_document_two_attachments');
  });
}

/// The previews inside the open details sheet.
///
/// Scoped to the sheet because the list rows behind it now carry thumbnails
/// of their own, so an unscoped `find.byType(CachedNetworkImage)` counts
/// those too.
Finder _sheetImages() => find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.byType(CachedNetworkImage),
    );

/// Closes the open details bottom sheet.
///
/// The sheet is a `DraggableScrollableSheet` at 0.65 of the height, so the
/// scrim is the top third of the screen. `find.byType(ModalBarrier)` matches
/// more than one barrier here and tapping it does not reliably dismiss, so
/// tap a coordinate inside the scrim instead.
Future<void> _dismissSheet(WidgetTester tester) async {
  await tester.tapAt(const Offset(200, 60));
  await tester.pumpAndSettle();
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
