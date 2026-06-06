import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';

abstract interface class FirebaseAiLogicDataSource {
  Future<SmartInputDraft> structureUserInput(String input);

  Future<SmartInputDraft> structureDocumentText(String text);
}
