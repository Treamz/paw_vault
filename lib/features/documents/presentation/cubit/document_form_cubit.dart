import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_events.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/documents/application/document_upload_service.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/documents/presentation/models/pet_document_form_state.dart';

class DocumentFormCubit extends Cubit<DocumentFormState> {
  DocumentFormCubit({
    required DocumentRepository documentRepository,
    required AuthRepository authRepository,
    required DocumentUploadService uploadService,
    required StorageRepository storageRepository,
    AnalyticsService? analytics,
  })  : _documentRepository = documentRepository,
        _authRepository = authRepository,
        _uploadService = uploadService,
        _storageRepository = storageRepository,
        _analytics = analytics ?? const NoopAnalyticsService(),
        super(const DocumentFormState());

  final DocumentRepository _documentRepository;
  final AuthRepository _authRepository;
  final DocumentUploadService _uploadService;
  final StorageRepository _storageRepository;
  final AnalyticsService _analytics;

  Future<void> load(String petId, String documentId) async {
    emit(
      DocumentFormState(
        status: DocumentFormStatus.loading,
        petId: petId,
        documentId: documentId,
      ),
    );

    try {
      await _documentRepository.initialize();
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final userId = EntityId(user.id);
      final document = await _documentRepository.getDocument(
        userId: userId,
        petId: EntityId(petId),
        documentId: EntityId(documentId),
      );

      emit(
        DocumentFormState(
          status: document == null
              ? DocumentFormStatus.notFound
              : DocumentFormStatus.ready,
          userId: userId,
          petId: petId,
          documentId: documentId,
          document: document,
        ),
      );
    } catch (error) {
      emit(
        DocumentFormState(
          status: DocumentFormStatus.failure,
          petId: petId,
          documentId: documentId,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Saves a new document. [file] is optional: when provided it is uploaded
  /// and linked to the document; without it only the metadata is saved.
  Future<void> createDocument(
    String petId,
    PetDocumentFormState formState, {
    PickedFile? file,
  }) async {
    // Validate before uploading so invalid metadata never leaves an orphaned
    // file in storage.
    final validation = formState.validate();
    if (!validation.isValid) {
      emit(
        state.copyWith(
          status: DocumentFormStatus.failure,
          errorMessage: 'Please fix validation errors',
        ),
      );
      return;
    }

    emit(state.copyWith(status: DocumentFormStatus.saving));

    try {
      await _documentRepository.initialize();
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final userId = EntityId(user.id);
      final entityPetId = EntityId(petId);
      final now = DateTime.now();
      final documentId = EntityId('${now.microsecondsSinceEpoch}');

      StorageFile? uploaded;
      if (file != null) {
        uploaded = await _uploadService.uploadDocumentFile(
          userId: userId,
          petId: entityPetId,
          documentId: documentId,
          file: file,
        );
      }

      final document = formState.toDocument(
        id: documentId,
        userId: userId,
        petId: entityPetId,
        fileUrl: uploaded?.downloadUrl,
        storagePath: uploaded?.path,
        createdAt: now,
        updatedAt: now,
      );

      await _documentRepository.saveDocument(document);
      _analytics.logEvent(
        AnalyticsEvents.documentUploaded,
        parameters: {AnalyticsParams.type: document.type.name},
      );

      emit(
        DocumentFormState(
          status: DocumentFormStatus.ready,
          userId: userId,
          petId: petId,
          documentId: documentId.value,
          document: document,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: DocumentFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> updateDocument(PetDocumentFormState formState) async {
    final currentDocument = state.document;
    if (currentDocument == null) {
      emit(
        state.copyWith(
          status: DocumentFormStatus.failure,
          errorMessage: 'Cannot update: no document loaded',
        ),
      );
      return;
    }

    emit(state.copyWith(status: DocumentFormStatus.saving));

    try {
      await _documentRepository.initialize();
      final now = DateTime.now();

      final updatedDocument = formState.toDocument(
        id: currentDocument.id,
        userId: currentDocument.userId,
        petId: currentDocument.petId,
        fileUrl: currentDocument.fileUrl,
        storagePath: currentDocument.storagePath,
        linkedEventId: currentDocument.linkedEventId,
        createdAt: currentDocument.createdAt?.value,
        updatedAt: now,
      );

      await _documentRepository.saveDocument(updatedDocument);

      emit(
        state.copyWith(
          status: DocumentFormStatus.ready,
          document: updatedDocument,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: DocumentFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> deleteDocument() async {
    final currentDocument = state.document;
    if (currentDocument == null) {
      emit(
        state.copyWith(
          status: DocumentFormStatus.failure,
          errorMessage: 'Cannot delete: no document loaded',
        ),
      );
      return;
    }

    emit(state.copyWith(status: DocumentFormStatus.deleting));

    try {
      await _documentRepository.initialize();
      // Remove the stored file first; only drop the metadata once the file is
      // gone so a failed storage delete leaves a consistent, retryable record.
      final storagePath = currentDocument.storagePath;
      if (storagePath != null) {
        await _storageRepository.delete(storagePath);
      }
      await _documentRepository.deleteDocument(
        userId: currentDocument.userId,
        petId: currentDocument.petId,
        documentId: currentDocument.id,
      );

      emit(
        DocumentFormState(
          status: DocumentFormStatus.ready,
          userId: state.userId,
          petId: state.petId,
          documentId: state.documentId,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: DocumentFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}

enum DocumentFormStatus {
  initial,
  loading,
  ready,
  saving,
  deleting,
  notFound,
  failure,
}

class DocumentFormState {
  const DocumentFormState({
    this.status = DocumentFormStatus.initial,
    this.userId,
    this.petId,
    this.documentId,
    this.document,
    this.errorMessage,
  });

  final DocumentFormStatus status;
  final EntityId? userId;
  final String? petId;
  final String? documentId;
  final PetDocument? document;
  final String? errorMessage;

  bool get isReady => status == DocumentFormStatus.ready;

  DocumentFormState copyWith({
    DocumentFormStatus? status,
    EntityId? userId,
    String? petId,
    String? documentId,
    PetDocument? document,
    String? errorMessage,
  }) {
    return DocumentFormState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      documentId: documentId ?? this.documentId,
      document: document ?? this.document,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
