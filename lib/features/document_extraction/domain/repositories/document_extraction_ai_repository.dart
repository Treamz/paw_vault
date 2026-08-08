import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_page.dart';

/// Port for AI-powered document extraction.
///
/// Implementations return a [DocumentExtractionDraft] only — they never persist
/// data. Saving requires explicit user confirmation.
abstract interface class DocumentExtractionAiRepository {
  /// Extracts one draft from all [pages] of a document together.
  Future<DocumentExtractionDraft> extractDocument({
    required List<DocumentPage> pages,
  });
}
