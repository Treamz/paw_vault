import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/documents/application/document_upload_service.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/documents/presentation/cubit/document_form_cubit.dart';
import 'package:paw_vault/features/documents/presentation/models/pet_document_form_state.dart';

void main() {
  group('DocumentFormCubit', () {
    test('createDocument uploads the file then saves the metadata', () async {
      final documentRepository = _FakeDocumentRepository();
      final cubit = _cubit(
        documentRepository: documentRepository,
        picked: _pickedFile(),
      );

      await cubit.createDocument(
        'pet-1',
        const PetDocumentFormState(
          type: PetDocumentType.passport,
          title: 'EU Pet Passport',
        ),
      );

      expect(cubit.state.status, DocumentFormStatus.ready);
      final saved = documentRepository.savedDocument;
      expect(saved, isNotNull);
      expect(saved!.title, 'EU Pet Passport');
      expect(saved.type, PetDocumentType.passport);
      expect(
        saved.storagePath,
        startsWith('users/user-1/pets/pet-1/documents/'),
      );
      expect(saved.fileUrl.toString(), contains('original.pdf'));
      expect(cubit.state.document, saved);
    });

    test('createDocument aborts without saving when picker is cancelled',
        () async {
      final documentRepository = _FakeDocumentRepository();
      final cubit = _cubit(
        documentRepository: documentRepository,
        picked: null,
      );

      await cubit.createDocument(
        'pet-1',
        const PetDocumentFormState(
          type: PetDocumentType.passport,
          title: 'EU Pet Passport',
        ),
      );

      expect(documentRepository.savedDocument, isNull);
      expect(documentRepository.saveCallCount, isZero);
      expect(cubit.state.status, DocumentFormStatus.initial);
    });

    test('createDocument emits failure when saving throws', () async {
      final documentRepository = _FakeDocumentRepository(throwsOnSave: true);
      final cubit = _cubit(
        documentRepository: documentRepository,
        picked: _pickedFile(),
      );

      await cubit.createDocument(
        'pet-1',
        const PetDocumentFormState(
          type: PetDocumentType.passport,
          title: 'EU Pet Passport',
        ),
      );

      expect(cubit.state.status, DocumentFormStatus.failure);
      expect(cubit.state.errorMessage, contains('save failed'));
    });

    test('load then updateDocument saves edited metadata reusing the file',
        () async {
      final existing = _document();
      final documentRepository = _FakeDocumentRepository(document: existing);
      final cubit = _cubit(
        documentRepository: documentRepository,
        picked: _pickedFile(),
      );

      await cubit.load('pet-1', 'doc-1');
      expect(cubit.state.status, DocumentFormStatus.ready);

      await cubit.updateDocument(
        const PetDocumentFormState(
          type: PetDocumentType.insurance,
          title: 'Updated insurance',
        ),
      );

      final saved = documentRepository.savedDocument;
      expect(cubit.state.status, DocumentFormStatus.ready);
      expect(saved!.id, existing.id);
      expect(saved.title, 'Updated insurance');
      expect(saved.type, PetDocumentType.insurance);
      // File details are reused from the existing document, not re-uploaded.
      expect(saved.fileUrl, existing.fileUrl);
      expect(saved.storagePath, existing.storagePath);
      expect(saved.createdAt, existing.createdAt);
    });

    test('updateDocument fails when no document is loaded', () async {
      final documentRepository = _FakeDocumentRepository();
      final cubit = _cubit(
        documentRepository: documentRepository,
        picked: _pickedFile(),
      );

      await cubit.updateDocument(
        const PetDocumentFormState(
          type: PetDocumentType.insurance,
          title: 'Updated insurance',
        ),
      );

      expect(cubit.state.status, DocumentFormStatus.failure);
      expect(documentRepository.saveCallCount, isZero);
    });

    test('load emits notFound when the document does not exist', () async {
      final documentRepository = _FakeDocumentRepository();
      final cubit = _cubit(
        documentRepository: documentRepository,
        picked: _pickedFile(),
      );

      await cubit.load('pet-1', 'missing');

      expect(cubit.state.status, DocumentFormStatus.notFound);
    });
  });
}

DocumentFormCubit _cubit({
  required _FakeDocumentRepository documentRepository,
  required PickedFile? picked,
}) {
  return DocumentFormCubit(
    documentRepository: documentRepository,
    authRepository: _FakeAuthRepository(
      currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
    ),
    uploadService: DocumentUploadService(
      filePicker: _FakeFilePicker(picked: picked),
      storageRepository: _FakeStorageRepository(),
    ),
  );
}

PickedFile _pickedFile() {
  return PickedFile(
    bytes: Uint8List.fromList([1, 2, 3]),
    fileName: 'passport.pdf',
    extension: 'pdf',
    contentType: 'application/pdf',
  );
}

PetDocument _document() {
  return PetDocument(
    id: const EntityId('doc-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    title: 'Original insurance',
    type: PetDocumentType.insurance,
    fileUrl: Uri.parse('https://storage.example.com/original.pdf'),
    storagePath: 'users/user-1/pets/pet-1/documents/doc-1/original.pdf',
    createdAt: null,
    issueDate: const DateOnly(year: 2024, month: 1, day: 1),
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.currentUserValue});

  final AppUser? currentUserValue;

  @override
  Future<AppUser?> currentUser() async => currentUserValue;

  @override
  Future<AppUser> signInAnonymously() async =>
      const AppUser(id: 'signed-in-user', isAnonymous: true);

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() =>
      Stream<AppUser?>.value(currentUserValue);
}

class _FakeDocumentRepository implements DocumentRepository {
  _FakeDocumentRepository({
    this.document,
    this.throwsOnSave = false,
  });

  final PetDocument? document;
  final bool throwsOnSave;

  int saveCallCount = 0;
  PetDocument? savedDocument;

  @override
  Future<void> deleteDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {}

  @override
  Future<PetDocument?> getDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {
    return document;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveDocument(PetDocument document) async {
    saveCallCount++;
    if (throwsOnSave) {
      throw StateError('save failed');
    }
    savedDocument = document;
  }

  @override
  Stream<List<PetDocument>> watchDocuments({
    required EntityId userId,
    required EntityId petId,
  }) {
    return const Stream<List<PetDocument>>.empty();
  }
}

class _FakeFilePicker implements FilePicker {
  _FakeFilePicker({this.picked});

  final PickedFile? picked;

  @override
  Future<PickedFile?> pickDocument() async => picked;
}

class _FakeStorageRepository implements StorageRepository {
  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    return StorageFile(
      path: path,
      downloadUrl: Uri.parse('https://storage.example.com/$path'),
    );
  }

  @override
  Future<void> delete(String path) async {}
}
