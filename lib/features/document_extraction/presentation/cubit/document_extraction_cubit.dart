import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_page.dart';
import 'package:paw_vault/features/document_extraction/domain/repositories/document_extraction_ai_repository.dart';
import 'package:paw_vault/features/document_extraction/domain/services/document_source_picker.dart';
import 'package:paw_vault/features/documents/application/document_upload_service.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/documents/presentation/models/pet_document_form_state.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';

class DocumentExtractionCubit extends Cubit<DocumentExtractionState> {
  DocumentExtractionCubit({
    required DocumentSourcePicker picker,
    required DocumentExtractionAiRepository aiRepository,
    required AuthRepository authRepository,
    required DocumentRepository documentRepository,
    required DocumentUploadService uploadService,
    SmartInputRepository? smartInputRepository,
  })  : _picker = picker,
        _aiRepository = aiRepository,
        _authRepository = authRepository,
        _documentRepository = documentRepository,
        _uploadService = uploadService,
        _smartInputRepository = smartInputRepository,
        super(const DocumentExtractionState());

  final DocumentSourcePicker _picker;
  final DocumentExtractionAiRepository _aiRepository;
  final AuthRepository _authRepository;
  final DocumentRepository _documentRepository;
  final DocumentUploadService _uploadService;
  final SmartInputRepository? _smartInputRepository;

  /// Picks a file from [source] and asks the AI to extract its fields.
  /// Additional picks while reviewing append pages and re-analyze them all
  /// together — nothing is saved here.
  Future<void> pickAndExtract(DocumentSource source) async {
    final existingFiles = state.pickedFiles;
    emit(
      state.copyWith(status: DocumentExtractionStatus.picking),
    );

    try {
      final file = await _picker.pick(source);
      if (file == null) {
        // User cancelled the picker.
        emit(
          existingFiles.isEmpty
              ? const DocumentExtractionState()
              : state.copyWith(status: DocumentExtractionStatus.review),
        );
        return;
      }

      final files = [...existingFiles, file];
      emit(
        DocumentExtractionState(
          status: DocumentExtractionStatus.extracting,
          pickedFiles: files,
        ),
      );

      final draft = await _aiRepository.extractDocument(
        pages: [
          for (final picked in files)
            DocumentPage(bytes: picked.bytes, mimeType: picked.contentType),
        ],
      );

      emit(
        DocumentExtractionState(
          status: DocumentExtractionStatus.review,
          pickedFiles: files,
          draft: draft,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: DocumentExtractionStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Confirms the reviewed [formState], uploading the picked file and saving a
  /// document. Only called after the user explicitly approves the extraction.
  Future<void> confirmExtraction(
    String petId,
    PetDocumentFormState formState,
  ) async {
    final file = state.pickedFiles.firstOrNull;
    if (file == null) {
      emit(
        state.copyWith(
          status: DocumentExtractionStatus.failure,
          errorMessage: 'No file to save.',
        ),
      );
      return;
    }

    // Validate before uploading so invalid input never orphans a stored file.
    if (!formState.validate().isValid) {
      emit(
        state.copyWith(
          status: DocumentExtractionStatus.failure,
          errorMessage: 'Please fix validation errors',
        ),
      );
      return;
    }

    emit(state.copyWith(status: DocumentExtractionStatus.saving));

    try {
      final user = await _authRepository.currentUser() ??
          await _authRepository.signInAnonymously();
      final userId = EntityId(user.id);
      final entityPetId = EntityId(petId);
      final now = DateTime.now();
      final documentId = EntityId('${now.microsecondsSinceEpoch}');

      final uploaded = await _uploadService.uploadDocumentFile(
        userId: userId,
        petId: entityPetId,
        documentId: documentId,
        file: file,
      );

      final document = formState.toDocument(
        id: documentId,
        userId: userId,
        petId: entityPetId,
        fileUrl: uploaded.downloadUrl,
        storagePath: uploaded.path,
        createdAt: now,
        updatedAt: now,
      );

      await _documentRepository.saveDocument(document);

      // The analysis also lands in Smart Input's History so scanned
      // documents are reviewable alongside typed notes.
      final smartInput = _smartInputRepository;
      if (smartInput != null) {
        await smartInput.saveSmartMessage(
          SmartMessage(
            id: EntityId('${now.microsecondsSinceEpoch}-scan'),
            userId: userId,
            petId: entityPetId,
            originalText: 'Scanned document: ${document.title}',
            detectedIntent: SmartMessageIntent.addNote,
            extractedData: {
              'type': document.type.name,
              'title': document.title,
              if (document.issueDate != null)
                'issue date': document.issueDate.toString(),
              if (document.expiryDate != null)
                'expiry date': document.expiryDate.toString(),
              if (document.notes != null) 'notes': document.notes,
            },
            confidence: state.draft?.confidence ?? 0,
            status: SmartMessageStatus.confirmed,
            createdAt: UtcDateTime(now),
          ),
        );
      }

      emit(
        const DocumentExtractionState(
          status: DocumentExtractionStatus.confirmed,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: DocumentExtractionStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Discards the current extraction, returning to idle.
  void reset() {
    emit(const DocumentExtractionState());
  }
}

enum DocumentExtractionStatus {
  idle,
  picking,
  extracting,
  review,
  saving,
  confirmed,
  failure,
}

class DocumentExtractionState {
  const DocumentExtractionState({
    this.status = DocumentExtractionStatus.idle,
    this.pickedFiles = const [],
    this.draft,
    this.errorMessage,
  });

  final DocumentExtractionStatus status;
  final List<PickedFile> pickedFiles;
  final DocumentExtractionDraft? draft;
  final String? errorMessage;

  bool get isBusy =>
      status == DocumentExtractionStatus.picking ||
      status == DocumentExtractionStatus.extracting ||
      status == DocumentExtractionStatus.saving;

  bool get hasDraft =>
      draft != null &&
      (status == DocumentExtractionStatus.review ||
          status == DocumentExtractionStatus.saving);

  DocumentExtractionState copyWith({
    DocumentExtractionStatus? status,
    List<PickedFile>? pickedFiles,
    DocumentExtractionDraft? draft,
    String? errorMessage,
  }) {
    return DocumentExtractionState(
      status: status ?? this.status,
      pickedFiles: pickedFiles ?? this.pickedFiles,
      draft: draft ?? this.draft,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
