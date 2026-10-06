import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/document_extraction/domain/services/document_source_picker.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/domain/services/document_file_opener.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/documents/presentation/screens/document_form_screen.dart';

void main() {
  group('DocumentFormScreen attached file', () {
    testWidgets('edit mode shows the attached file and opens it externally',
        (tester) async {
      final opener = _FakeDocumentFileOpener();
      await tester.pumpWidget(_app(document: _document(), opener: opener));
      await tester.pumpAndSettle();

      expect(find.text('Attached file'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      // PDFs have no inline preview.
      expect(find.byType(Image), findsNothing);

      await tester.tap(find.text('Attached file'));
      await tester.pumpAndSettle();

      expect(opener.openedUrl, Uri.parse('https://example.com/doc.pdf'));
    });

    testWidgets('shows an inline preview for image documents', (tester) async {
      final document = _document(
        fileUrl: 'https://example.com/doc.jpg',
        storagePath: 'users/user-1/pets/pet-1/documents/doc-1/original.jpg',
      );
      await tester.pumpWidget(
        _app(document: document, opener: _FakeDocumentFileOpener()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Attached file'), findsOneWidget);
      expect(find.text('JPG'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets(
        'notes is not labeled optional, the issue date says it is '
        'required, and notes is a large field', (tester) async {
      await tester.pumpWidget(
        _app(document: null, opener: _FakeDocumentFileOpener()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Notes (optional)'), findsNothing);
      expect(find.text('Issue date (required)'), findsOneWidget);
      expect(find.text('Issue date (optional)'), findsNothing);

      final notesField = tester.widget<TextField>(
        find.descendant(
          of: find.ancestor(
            of: find.text('Notes'),
            matching: find.byType(TextFormField),
          ),
          matching: find.byType(TextField),
        ),
      );
      expect(notesField.maxLines, 6);
    });

    testWidgets('one gallery pick attaches several files, and each can go',
        (tester) async {
      // Asked for by QA: picking several photos should not mean opening the
      // picker once per photo.
      await tester.pumpWidget(
        _app(
          document: null,
          opener: _FakeDocumentFileOpener(),
          sourcePicker: _FakeSourcePicker(
            files: [
              _pickedFile('page_1.jpg'),
              _pickedFile('page_2.jpg'),
              _pickedFile('page_3.jpg'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Attach photos or files (optional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();

      expect(find.text('page_1.jpg'), findsOneWidget);
      expect(find.text('page_2.jpg'), findsOneWidget);
      expect(find.text('page_3.jpg'), findsOneWidget);
      // Still room to add more, rather than the picker replacing the lot.
      expect(find.text('Add more'), findsOneWidget);

      final removeSecond = find.byTooltip('Remove page_2.jpg');
      await tester.ensureVisible(removeSecond);
      await tester.pumpAndSettle();
      await tester.tap(removeSecond);
      await tester.pumpAndSettle();

      expect(find.text('page_2.jpg'), findsNothing);
      expect(find.text('page_1.jpg'), findsOneWidget);
      expect(find.text('page_3.jpg'), findsOneWidget);
    });

    testWidgets('create mode has no attached file section', (tester) async {
      await tester.pumpWidget(
        _app(document: null, opener: _FakeDocumentFileOpener()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Attached file'), findsNothing);
    });
  });
}

Widget _app({
  required PetDocument? document,
  required DocumentFileOpener opener,
  DocumentRepository? repository,
  DocumentSourcePicker? sourcePicker,
}) {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: _FakeAuthRepository()),
      RepositoryProvider<DocumentRepository>.value(
        value: repository ?? _FakeDocumentRepository(document),
      ),
      RepositoryProvider<StorageRepository>.value(
        value: _FakeStorageRepository(),
      ),
      RepositoryProvider<FilePicker>.value(value: _FakeFilePicker()),
      RepositoryProvider<AnalyticsService>.value(
        value: const NoopAnalyticsService(),
      ),
      RepositoryProvider<DocumentFileOpener>.value(value: opener),
      RepositoryProvider<DocumentSourcePicker>.value(
        value: sourcePicker ?? _FakeSourcePicker(),
      ),
    ],
    child: MaterialApp(
      home: DocumentFormScreen(
        petId: 'pet-1',
        documentId: document?.id.value,
      ),
    ),
  );
}

/// Hands back [files] for a gallery pick, so the multi-select path can be
/// driven without a platform picker.
class _FakeSourcePicker implements DocumentSourcePicker {
  _FakeSourcePicker({this.files = const []});

  final List<PickedFile> files;

  @override
  Future<PickedFile?> pick(DocumentSource source) async => files.firstOrNull;

  @override
  Future<List<PickedFile>> pickMultipleFromGallery() async => files;
}

PickedFile _pickedFile(String name) {
  final extension = name.split('.').last;
  return PickedFile(
    bytes: Uint8List.fromList([1, 2, 3]),
    fileName: name,
    extension: extension,
    contentType: extension == 'pdf' ? 'application/pdf' : 'image/$extension',
  );
}

PetDocument _document({
  String fileUrl = 'https://example.com/doc.pdf',
  String storagePath = 'users/user-1/pets/pet-1/documents/doc-1/original.pdf',
}) {
  return PetDocument(
    id: const EntityId('doc-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    title: 'Vaccination certificate',
    type: PetDocumentType.vaccinationCertificate,
    fileUrl: Uri.parse(fileUrl),
    storagePath: storagePath,
  );
}

class _FakeDocumentFileOpener implements DocumentFileOpener {
  Uri? openedUrl;

  @override
  Future<bool> open(Uri fileUrl) async {
    openedUrl = fileUrl;
    return true;
  }
}

class _FakeAuthRepository implements AuthRepository {
  static const _user = AppUser(id: 'user-1', isAnonymous: true);

  @override
  Future<AppUser?> currentUser() async => _user;

  @override
  Future<AppUser> signInAnonymously() async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() => Stream<AppUser?>.value(_user);
}

class _FakeDocumentRepository implements DocumentRepository {
  _FakeDocumentRepository(this.document);

  final PetDocument? document;

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PetDocument>> watchDocuments({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream.value([if (document != null) document!]);

  @override
  Future<PetDocument?> getDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async =>
      document;

  @override
  Future<void> saveDocument(PetDocument document) async {}

  @override
  Future<void> deleteDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {}
}

class _FakeStorageRepository implements StorageRepository {
  @override
  Future<void> delete(String path) async {}

  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async =>
      StorageFile(
        path: path,
        downloadUrl: Uri.parse('https://example.com/$path'),
      );
}

class _FakeFilePicker implements FilePicker {
  @override
  Future<PickedFile?> pickDocument() async => null;

  @override
  Future<List<PickedFile>> pickDocuments() async =>
      pickDocument().then((file) => file == null ? <PickedFile>[] : [file]);
}
