import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/ai_repository.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';

class NoopSmartInputRepository implements SmartInputRepository {
  const NoopSmartInputRepository(this._aiRepository);

  final AiRepository _aiRepository;

  @override
  Future<SmartInputDraft> createDraft(String input) {
    return _aiRepository.structureUserInput(input);
  }
}
