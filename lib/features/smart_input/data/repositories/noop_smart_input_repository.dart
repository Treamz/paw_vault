import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/ai_repository.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';

class NoopSmartInputRepository implements SmartInputRepository {
  const NoopSmartInputRepository(this._aiRepository);

  final AiRepository _aiRepository;

  @override
  Future<SmartInputDraft> createDraft(String input) {
    return _aiRepository.structureUserInput(input);
  }

  @override
  Future<void> deleteSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async {}

  @override
  Future<SmartMessage?> getSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) async {
    return null;
  }

  @override
  Future<void> saveSmartMessage(SmartMessage message) async {}

  @override
  Stream<List<SmartMessage>> watchSmartMessages({
    required EntityId userId,
    required EntityId petId,
  }) {
    return Stream<List<SmartMessage>>.value(const []);
  }
}
