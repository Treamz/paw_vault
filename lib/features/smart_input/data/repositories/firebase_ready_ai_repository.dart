import 'package:paw_vault/core/ai/data/datasources/firebase_ai_logic_data_source.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/ai_repository.dart';

class FirebaseReadyAiRepository implements AiRepository {
  const FirebaseReadyAiRepository(this._dataSource);

  final FirebaseAiLogicDataSource _dataSource;

  @override
  Future<SmartInputDraft> structureDocumentText(String text) {
    return _dataSource.structureDocumentText(text);
  }

  @override
  Future<SmartInputDraft> structureUserInput(String input) {
    return _dataSource.structureUserInput(input);
  }
}
