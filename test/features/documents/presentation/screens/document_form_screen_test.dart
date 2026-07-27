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
        'notes and issue date are not labeled optional and notes '
        'is a large field', (tester) async {
      await tester.pumpWidget(
        _app(document: null, opener: _FakeDocumentFileOpener()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Notes (optional)'), findsNothing);
      expect(find.text('Issue date'), findsOneWidget);
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
    ],
    child: MaterialApp(
      home: DocumentFormScreen(
        petId: 'pet-1',
        documentId: document?.id.value,
      ),
    ),
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
}
