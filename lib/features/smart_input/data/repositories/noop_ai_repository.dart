import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/ai_repository.dart';

class NoopAiRepository implements AiRepository {
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
}
