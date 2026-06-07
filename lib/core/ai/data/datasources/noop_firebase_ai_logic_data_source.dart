import 'dart:typed_data';

import 'package:paw_vault/core/ai/data/datasources/firebase_ai_logic_data_source.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';

class NoopFirebaseAiLogicDataSource implements FirebaseAiLogicDataSource {
  @override
  Future<SmartInputDraft> structureDocumentText(String text) async {
    return SmartInputDraft(
      originalText: text,
      requiresConfirmation: true,
    );
  }

  @override
  Future<SmartInputDraft> structureUserInput(String input) async {
    return SmartInputDraft(
      originalText: input,
      requiresConfirmation: true,
    );
  }

  @override
  Future<DocumentExtractionDraft> extractDocument({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    return const DocumentExtractionDraft(requiresConfirmation: true);
  }
}
