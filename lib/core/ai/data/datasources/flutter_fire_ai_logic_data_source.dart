import 'package:firebase_ai/firebase_ai.dart';
import 'package:paw_vault/core/ai/data/datasources/firebase_ai_logic_data_source.dart';
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
