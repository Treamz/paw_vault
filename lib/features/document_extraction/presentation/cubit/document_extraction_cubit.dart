import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/document_extraction/domain/repositories/document_extraction_ai_repository.dart';
import 'package:paw_vault/features/document_extraction/domain/services/document_source_picker.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';

class DocumentExtractionCubit extends Cubit<DocumentExtractionState> {
  DocumentExtractionCubit({
    required DocumentSourcePicker picker,
    required DocumentExtractionAiRepository aiRepository,
  })  : _picker = picker,
        _aiRepository = aiRepository,
        super(const DocumentExtractionState());

  final DocumentSourcePicker _picker;
  final DocumentExtractionAiRepository _aiRepository;

  /// Picks a file from [source] and asks the AI to extract its fields. The
  /// result is surfaced as a draft for review — nothing is saved here.
  Future<void> pickAndExtract(DocumentSource source) async {
    emit(const DocumentExtractionState(
        status: DocumentExtractionStatus.picking));

    try {
      final file = await _picker.pick(source);
      if (file == null) {
        // User cancelled the picker.
        emit(const DocumentExtractionState());
        return;
      }

      emit(
        DocumentExtractionState(
          status: DocumentExtractionStatus.extracting,
          pickedFile: file,
        ),
      );

      final draft = await _aiRepository.extractDocument(
        bytes: file.bytes,
        mimeType: file.contentType,
      );

      emit(
        DocumentExtractionState(
          status: DocumentExtractionStatus.review,
          pickedFile: file,
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
  failure,
}

class DocumentExtractionState {
  const DocumentExtractionState({
    this.status = DocumentExtractionStatus.idle,
    this.pickedFile,
    this.draft,
    this.errorMessage,
  });

  final DocumentExtractionStatus status;
  final PickedFile? pickedFile;
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
    PickedFile? pickedFile,
    DocumentExtractionDraft? draft,
    String? errorMessage,
  }) {
    return DocumentExtractionState(
      status: status ?? this.status,
      pickedFile: pickedFile ?? this.pickedFile,
      draft: draft ?? this.draft,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
