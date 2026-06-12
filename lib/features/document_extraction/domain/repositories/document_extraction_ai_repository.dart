import 'dart:typed_data';

import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';

/// Port for AI-powered document extraction.
///
/// Implementations return a [DocumentExtractionDraft] only — they never persist
/// data. Saving requires explicit user confirmation.
abstract interface class DocumentExtractionAiRepository {
  Future<DocumentExtractionDraft> extractDocument({
    required Uint8List bytes,
    required String mimeType,
  });
}
