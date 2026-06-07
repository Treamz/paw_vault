import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/document_extraction/domain/repositories/document_extraction_ai_repository.dart';
import 'package:paw_vault/features/document_extraction/domain/services/document_source_picker.dart';
import 'package:paw_vault/features/document_extraction/presentation/cubit/document_extraction_cubit.dart';
import 'package:paw_vault/features/documents/application/document_upload_service.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/documents/presentation/models/pet_document_form_state.dart';

void main() {
  group('DocumentExtractionCubit', () {
    test('picks a file and surfaces the extracted draft for review', () async {
      final picker = _FakePicker(file: _pickedFile());
      final aiRepository = _FakeAiRepository(draft: _draft());
      final cubit = _cubit(picker: picker, aiRepository: aiRepository);
      final states = <DocumentExtractionState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.pickAndExtract(DocumentSource.camera);
      await Future<void>.delayed(Duration.zero);

      expect(picker.requestedSource, DocumentSource.camera);
      expect(aiRepository.mimeType, 'application/pdf');
      expect(aiRepository.byteCount, 3);
      expect(states.map((s) => s.status), [
        DocumentExtractionStatus.picking,
        DocumentExtractionStatus.extracting,
        DocumentExtractionStatus.review,
      ]);
      expect(cubit.state.draft?.detectedType,
          PetDocumentType.vaccinationCertificate);
      expect(cubit.state.pickedFile, isNotNull);
      expect(cubit.state.hasDraft, isTrue);

      await subscription.cancel();
      await cubit.close();
    });

    test('returns to idle without extracting when the picker is cancelled',
        () async {
      final picker = _FakePicker(file: null);
      final aiRepository = _FakeAiRepository(draft: _draft());
      final cubit = _cubit(picker: picker, aiRepository: aiRepository);

      await cubit.pickAndExtract(DocumentSource.gallery);

      expect(cubit.state.status, DocumentExtractionStatus.idle);
      expect(aiRepository.callCount, isZero);

      await cubit.close();
    });

    test('emits failure when extraction throws', () async {
      final picker = _FakePicker(file: _pickedFile());
      final aiRepository = _FakeAiRepository(throwsOnExtract: true);
      final cubit = _cubit(picker: picker, aiRepository: aiRepository);

      await cubit.pickAndExtract(DocumentSource.file);

      expect(cubit.state.status, DocumentExtractionStatus.failure);
      expect(cubit.state.errorMessage, contains('extract failed'));

      await cubit.close();
    });

    test('confirmExtraction uploads the file and saves the document', () async {
      final documentRepository = _FakeDocumentRepository();
      final storageRepository = _FakeStorageRepository();
      final cubit = _cubit(
        picker: _FakePicker(file: _pickedFile()),
        aiRepository: _FakeAiRepository(draft: _draft()),
        documentRepository: documentRepository,
        storageRepository: storageRepository,
      );

      await cubit.pickAndExtract(DocumentSource.camera);
      await cubit.confirmExtraction(
        'pet-1',
        const PetDocumentFormState(
          type: PetDocumentType.vaccinationCertificate,
          title: 'Rabies vaccination',
        ),
      );

      expect(storageRepository.uploadedPath,
          startsWith('users/user-1/pets/pet-1/documents/'));
      final saved = documentRepository.savedDocument;
      expect(saved, isNotNull);
      expect(saved!.title, 'Rabies vaccination');
      expect(saved.type, PetDocumentType.vaccinationCertificate);
      expect(saved.storagePath, storageRepository.uploadedPath);
      expect(cubit.state.status, DocumentExtractionStatus.confirmed);

      await cubit.close();
    });

    test('confirmExtraction fails when no file was picked', () async {
      final documentRepository = _FakeDocumentRepository();
      final cubit = _cubit(
        picker: _FakePicker(file: _pickedFile()),
        aiRepository: _FakeAiRepository(draft: _draft()),
        documentRepository: documentRepository,
      );

      await cubit.confirmExtraction(
        'pet-1',
        const PetDocumentFormState(
          type: PetDocumentType.vaccinationCertificate,
          title: 'Rabies vaccination',
        ),
      );

      expect(cubit.state.status, DocumentExtractionStatus.failure);
      expect(documentRepository.saveCallCount, isZero);

      await cubit.close();
    });

    test('confirmExtraction rejects invalid input without uploading', () async {
      final documentRepository = _FakeDocumentRepository();
      final storageRepository = _FakeStorageRepository();
      final cubit = _cubit(
        picker: _FakePicker(file: _pickedFile()),
        aiRepository: _FakeAiRepository(draft: _draft()),
        documentRepository: documentRepository,
        storageRepository: storageRepository,
      );

      await cubit.pickAndExtract(DocumentSource.camera);
      await cubit.confirmExtraction(
        'pet-1',
        const PetDocumentFormState(title: ''),
      );

      expect(cubit.state.status, DocumentExtractionStatus.failure);
      expect(storageRepository.uploadCallCount, isZero);
      expect(documentRepository.saveCallCount, isZero);

      await cubit.close();
    });
  });
}

DocumentExtractionCubit _cubit({
  required _FakePicker picker,
  required _FakeAiRepository aiRepository,
  _FakeDocumentRepository? documentRepository,
  _FakeStorageRepository? storageRepository,
}) {
  final storage = storageRepository ?? _FakeStorageRepository();
  return DocumentExtractionCubit(
    picker: picker,
    aiRepository: aiRepository,
    authRepository: _FakeAuthRepository(
      currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
    ),
    documentRepository: documentRepository ?? _FakeDocumentRepository(),
    uploadService: DocumentUploadService(
      filePicker: _UnusedFilePicker(),
      storageRepository: storage,
    ),
  );
}

PickedFile _pickedFile() {
  return PickedFile(
    bytes: Uint8List.fromList([1, 2, 3]),
    fileName: 'vax.pdf',
    extension: 'pdf',
    contentType: 'application/pdf',
  );
}

DocumentExtractionDraft _draft() {
  return const DocumentExtractionDraft(
    requiresConfirmation: true,
    detectedType: PetDocumentType.vaccinationCertificate,
    title: 'Rabies vaccination',
    confidence: 0.9,
  );
}

class _FakePicker implements DocumentSourcePicker {
  _FakePicker({this.file});

  final PickedFile? file;
  DocumentSource? requestedSource;

  @override
  Future<PickedFile?> pick(DocumentSource source) async {
    requestedSource = source;
    return file;
  }
}

class _FakeAiRepository implements DocumentExtractionAiRepository {
  _FakeAiRepository({
    this.draft,
    this.throwsOnExtract = false,
  });

  final DocumentExtractionDraft? draft;
  final bool throwsOnExtract;

  int callCount = 0;
  String? mimeType;
  int? byteCount;

  @override
  Future<DocumentExtractionDraft> extractDocument({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    callCount++;
    this.mimeType = mimeType;
    byteCount = bytes.length;
    if (throwsOnExtract) {
      throw StateError('extract failed');
    }
    return draft!;
  }
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
  }) async =>
      null;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveDocument(PetDocument document) async {
    saveCallCount++;
    savedDocument = document;
  }

  @override
  Stream<List<PetDocument>> watchDocuments({
    required EntityId userId,
    required EntityId petId,
  }) =>
      const Stream<List<PetDocument>>.empty();
}

class _FakeStorageRepository implements StorageRepository {
  int uploadCallCount = 0;
  String? uploadedPath;

  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadCallCount++;
    uploadedPath = path;
    return StorageFile(
      path: path,
      downloadUrl: Uri.parse('https://storage.example.com/$path'),
    );
  }

  @override
  Future<void> delete(String path) async {}
}

class _UnusedFilePicker implements FilePicker {
  @override
  Future<PickedFile?> pickDocument() async => null;
}
