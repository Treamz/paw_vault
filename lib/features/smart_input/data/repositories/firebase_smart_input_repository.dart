import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/smart_input/data/datasources/firestore_smart_input_data_source.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/ai_repository.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';

class FirebaseSmartInputRepository implements SmartInputRepository {
  const FirebaseSmartInputRepository({
    required AiRepository aiRepository,
    required FirestoreSmartInputDataSource dataSource,
  })  : _aiRepository = aiRepository,
        _dataSource = dataSource;

  final AiRepository _aiRepository;
  final FirestoreSmartInputDataSource _dataSource;

  @override
  Future<SmartInputDraft> createDraft(String input) {
    return _aiRepository.structureUserInput(input);
  }

  @override
  Future<void> deleteSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) {
    return _dataSource.deleteSmartMessage(
      userId: userId.value,
      petId: petId.value,
      messageId: messageId.value,
    );
  }

  @override
  Future<SmartMessage?> getSmartMessage({
    required EntityId userId,
    required EntityId petId,
    required EntityId messageId,
  }) {
    return _dataSource.getSmartMessage(
      userId: userId.value,
      petId: petId.value,
      messageId: messageId.value,
    );
  }

  @override
  Future<void> saveSmartMessage(SmartMessage message) {
    if (message.status != SmartMessageStatus.confirmed) {
      throw StateError(
        'Smart messages must be confirmed by the user before saving.',
      );
    }

    return _dataSource.saveSmartMessage(message);
  }

  @override
  Stream<List<SmartMessage>> watchSmartMessages({
    required EntityId userId,
    required EntityId petId,
  }) {
    return _dataSource.watchSmartMessages(
      userId: userId.value,
      petId: petId.value,
    );
  }
}
