import 'dart:typed_data';

import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';

abstract interface class FirebaseAiLogicDataSource {
  Future<SmartInputDraft> structureUserInput(String input);

  Future<SmartInputDraft> structureDocumentText(String text);

  /// Analyzes a document file (image or PDF) and returns suggested structured
  /// fields as a draft for user review. Never persists anything.
  Future<DocumentExtractionDraft> extractDocument({
    required Uint8List bytes,
    required String mimeType,
  });
}
