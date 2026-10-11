import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_page.dart';
import 'package:paw_vault/features/document_extraction/domain/repositories/document_extraction_ai_repository.dart';
import 'package:paw_vault/features/document_extraction/domain/services/document_source_picker.dart';
import 'package:paw_vault/features/document_extraction/presentation/cubit/document_extraction_cubit.dart';
import 'package:paw_vault/features/documents/application/document_upload_service.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/documents/presentation/models/pet_document_form_state.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';

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
      expect(aiRepository.lastPages, hasLength(1));
      expect(aiRepository.lastPages?.single.mimeType, 'application/pdf');
      expect(aiRepository.lastPages?.single.bytes, hasLength(3));
      expect(states.map((s) => s.status), [
        DocumentExtractionStatus.picking,
        DocumentExtractionStatus.extracting,
        DocumentExtractionStatus.review,
      ]);
      expect(
        cubit.state.draft?.detectedType,
        PetDocumentType.vaccinationCertificate,
      );
      expect(cubit.state.pickedFiles, hasLength(1));
      expect(cubit.state.hasDraft, isTrue);

      await subscription.cancel();
      await cubit.close();
    });

    test('returns to idle without extracting when the picker is cancelled',
        () async {
      final picker = _FakePicker();
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
        PetDocumentFormState(
          type: PetDocumentType.vaccinationCertificate,
          title: 'Rabies vaccination',
          issueDate: DateTime(2024, 1, 15),
        ),
      );

      expect(
        storageRepository.uploadedPath,
        startsWith('users/user-1/pets/pet-1/documents/'),
      );
      final saved = documentRepository.savedDocument;
      expect(saved, isNotNull);
      expect(saved!.title, 'Rabies vaccination');
      expect(saved.type, PetDocumentType.vaccinationCertificate);
      expect(saved.storagePath, storageRepository.uploadedPath);
      expect(cubit.state.status, DocumentExtractionStatus.confirmed);

      await cubit.close();
    });

    test('one gallery pick can bring several pages at once', () async {
      // Asked for by QA: selecting four photos should not mean four trips
      // through the picker.
      final picker = _FakePicker(
        multiple: [
          _pickedFile(name: 'page_1.jpg'),
          _pickedFile(name: 'page_2.jpg'),
          _pickedFile(name: 'page_3.jpg'),
        ],
      );
      final aiRepository = _FakeAiRepository(draft: _draft());
      final cubit = _cubit(picker: picker, aiRepository: aiRepository);

      await cubit.pickAndExtract(DocumentSource.gallery);

      expect(cubit.state.pickedFiles, hasLength(3));
      // All of them analysed together, in one AI request.
      expect(aiRepository.callCount, 1);
      expect(aiRepository.lastPages, hasLength(3));
      expect(cubit.state.status, DocumentExtractionStatus.review);

      await cubit.close();
    });

    test('appends pages and re-extracts all of them together', () async {
      final picker = _FakePicker(file: _pickedFile());
      final aiRepository = _FakeAiRepository(draft: _draft());
      final cubit = _cubit(picker: picker, aiRepository: aiRepository);

      await cubit.pickAndExtract(DocumentSource.camera);
      await cubit.pickAndExtract(DocumentSource.gallery);

      expect(cubit.state.status, DocumentExtractionStatus.review);
      expect(cubit.state.pickedFiles, hasLength(2));
      expect(aiRepository.callCount, 2);
      expect(aiRepository.lastPages, hasLength(2));

      await cubit.close();
    });

    test('keeps existing pages when an extra pick is cancelled', () async {
      final aiRepository = _FakeAiRepository(draft: _draft());
      final firstPicker = _FakePicker(file: _pickedFile());
      final cubit = _cubit(picker: firstPicker, aiRepository: aiRepository);

      await cubit.pickAndExtract(DocumentSource.camera);
      firstPicker.fileOverride = null;
      await cubit.pickAndExtract(DocumentSource.gallery);

      expect(cubit.state.status, DocumentExtractionStatus.review);
      expect(cubit.state.pickedFiles, hasLength(1));
      expect(aiRepository.callCount, 1);

      await cubit.close();
    });

    test('confirmExtraction uploads every scanned page', () async {
      // The reported bug: scanning two pages analysed both and saved only the
      // first, so the owner silently lost the second file.
      final documentRepository = _FakeDocumentRepository();
      final storageRepository = _FakeStorageRepository();
      final picker = _FakePicker(file: _pickedFile());
      final cubit = _cubit(
        picker: picker,
        aiRepository: _FakeAiRepository(draft: _draft()),
        documentRepository: documentRepository,
        storageRepository: storageRepository,
      );

      await cubit.pickAndExtract(DocumentSource.gallery);
      await cubit.pickAndExtract(DocumentSource.camera);
      expect(cubit.state.pickedFiles, hasLength(2));

      await cubit.confirmExtraction(
        'pet-1',
        PetDocumentFormState(
          type: PetDocumentType.vaccinationCertificate,
          title: 'Rabies vaccination',
          issueDate: DateTime(2024, 1, 15),
        ),
      );

      expect(storageRepository.uploadCallCount, 2);
      expect(storageRepository.uploadedPaths, hasLength(2));
      // Separate objects — a shared path would overwrite one with the other.
      expect(
        storageRepository.uploadedPaths.toSet(),
        hasLength(2),
      );

      final saved = documentRepository.savedDocument!;
      expect(saved.attachments, hasLength(2));
      expect(saved.files, hasLength(2));
      // The legacy pair stays populated so an older build still shows a file.
      expect(saved.fileUrl, isNotNull);
      expect(saved.storagePath, isNotNull);

      await cubit.close();
    });

    test('confirmExtraction saves the analysis to Smart Input history',
        () async {
      final smartInputRepository = _FakeSmartInputRepository();
      final cubit = _cubit(
        picker: _FakePicker(file: _pickedFile()),
        aiRepository: _FakeAiRepository(draft: _draft()),
        smartInputRepository: smartInputRepository,
      );

      await cubit.pickAndExtract(DocumentSource.camera);
      await cubit.confirmExtraction(
        'pet-1',
        PetDocumentFormState(
          type: PetDocumentType.vaccinationCertificate,
          title: 'Rabies vaccination',
          issueDate: DateTime(2024, 1, 15),
        ),
      );

      expect(cubit.state.status, DocumentExtractionStatus.confirmed);
      final message = smartInputRepository.savedMessages.single;
      expect(message.originalText, contains('Rabies vaccination'));
      expect(message.status, SmartMessageStatus.confirmed);
      expect(message.petId.value, 'pet-1');

      await cubit.close();
    });

    test('the Smart Input entry carries every scanned file', () async {
      // The reported bug: files attached in Smart Input were nowhere to be
      // seen in History, which showed text only.
      final smartInputRepository = _FakeSmartInputRepository();
      final documentRepository = _FakeDocumentRepository();
      final cubit = _cubit(
        picker: _FakePicker(file: _pickedFile()),
        aiRepository: _FakeAiRepository(draft: _draft()),
        documentRepository: documentRepository,
        smartInputRepository: smartInputRepository,
      );

      await cubit.pickAndExtract(DocumentSource.gallery);
      await cubit.pickAndExtract(DocumentSource.camera);
      await cubit.confirmExtraction(
        'pet-1',
        PetDocumentFormState(
          type: PetDocumentType.vaccinationCertificate,
          title: 'Rabies vaccination',
          issueDate: DateTime(2024, 1, 15),
        ),
      );

      final message = smartInputRepository.savedMessages.single;
      expect(message.attachments, hasLength(2));
      // The same files the document itself got, not a second upload.
      expect(message.attachments, documentRepository.savedDocument!.files);

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
        PetDocumentFormState(
          type: PetDocumentType.vaccinationCertificate,
          title: 'Rabies vaccination',
          issueDate: DateTime(2024, 1, 15),
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
        const PetDocumentFormState(),
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
  _FakeSmartInputRepository? smartInputRepository,
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
    smartInputRepository: smartInputRepository,
  );
}

PickedFile _pickedFile({String name = 'vax.pdf'}) {
  final extension = name.split('.').last;
  return PickedFile(
    bytes: Uint8List.fromList([1, 2, 3]),
    fileName: name,
    extension: extension,
    contentType: extension == 'pdf' ? 'application/pdf' : 'image/\$extension',
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
  _FakePicker({PickedFile? file, this.multiple}) : fileOverride = file;

  PickedFile? fileOverride;

  /// What the gallery hands back; defaults to [fileOverride] on its own.
  final List<PickedFile>? multiple;
  DocumentSource? requestedSource;

  @override
  Future<PickedFile?> pick(DocumentSource source) async {
    requestedSource = source;
    return fileOverride;
  }

  @override
  Future<List<PickedFile>> pickMultipleFromGallery() async {
    requestedSource = DocumentSource.gallery;
    final picked = multiple;
    if (picked != null) {
      return picked;
    }
    final single = fileOverride;
    return single == null ? const [] : [single];
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
  List<DocumentPage>? lastPages;

  @override
  Future<DocumentExtractionDraft> extractDocument({
    required List<DocumentPage> pages,
  }) async {
    callCount++;
    lastPages = pages;
    if (throwsOnExtract) {
      throw StateError('extract failed');
    }
    return draft!;
  }
}

class _FakeSmartInputRepository implements SmartInputRepository {
  final savedMessages = <SmartMessage>[];

  @override
  Future<SmartInputDraft> createDraft(String input) async =>
      SmartInputDraft(originalText: input, requiresConfirmation: true);

  @override
  Future<void> saveSmartMessage(SmartMessage message) async {
    savedMessages.add(message);
  }

  @override
  Future<SmartMessage?> getSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async =>
      null;

  @override
  Future<void> deleteSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async {}

  @override
  Stream<List<SmartMessage>> watchSmartMessages({
    required EntityId userId,
    required EntityId petId,
  }) =>
      const Stream<List<SmartMessage>>.empty();
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
  final uploadedPaths = <String>[];

  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadCallCount++;
    uploadedPath = path;
    uploadedPaths.add(path);
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

  @override
  Future<List<PickedFile>> pickDocuments() async =>
      pickDocument().then((file) => file == null ? <PickedFile>[] : [file]);
}
