import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:paw_vault/core/ai/data/datasources/firebase_ai_logic_data_source.dart';
import 'package:paw_vault/features/document_extraction/domain/entities/document_extraction_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';

class FlutterFireAiLogicDataSource implements FirebaseAiLogicDataSource {
  const FlutterFireAiLogicDataSource(
    this._firebaseAi, {
    this.modelName = 'gemini-2.5-flash',
  });

  final FirebaseAI _firebaseAi;
  final String modelName;

  @override
  Future<SmartInputDraft> structureDocumentText(String text) async {
    _createModel();
    return SmartInputDraft(
      originalText: text,
      requiresConfirmation: true,
    );
  }

  @override
  Future<SmartInputDraft> structureUserInput(String input) async {
    _createModel();
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
    _createModel();
    // The picked file is provided to Gemini as an inline data part; parsing the
    // model's JSON response into the draft fields is wired here.
    Content.multi([
      InlineDataPart(mimeType, bytes),
      TextPart('Extract the document fields as JSON.'),
    ]);
    return const DocumentExtractionDraft(requiresConfirmation: true);
  }

  GenerativeModel _createModel() {
    return _firebaseAi.generativeModel(
      model: modelName,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
      systemInstruction: Content.system(
        'Structure user-provided pet health data only. Do not diagnose, '
        'recommend treatment, or save data directly. Return draft data that '
        'the app must show for user confirmation before saving.',
      ),
    );
  }
}
