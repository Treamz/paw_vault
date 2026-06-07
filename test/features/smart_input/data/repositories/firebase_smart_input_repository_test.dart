import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/smart_input/data/datasources/firestore_smart_input_data_source.dart';
import 'package:paw_vault/features/smart_input/data/repositories/firebase_smart_input_repository.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/ai_repository.dart';

void main() {
  group('FirebaseSmartInputRepository', () {
    test('creates drafts through AI without saving to Firestore', () async {
      final draft = _draft();
      final aiRepository = _FakeAiRepository(draft: draft);
      final dataSource = _FakeFirestoreSmartInputDataSource();
      final repository = FirebaseSmartInputRepository(
        aiRepository: aiRepository,
        dataSource: dataSource,
      );

      final result = await repository.createDraft('Add rabies vaccine.');

      expect(result, draft);
      expect(aiRepository.structuredUserInput, 'Add rabies vaccine.');
      expect(dataSource.savedMessage, isNull);
    });

    test('watches messages through the Firestore data source', () async {
      final message = _message();
      final dataSource = _FakeFirestoreSmartInputDataSource(watchedMessages: [
        message,
      ]);
      final repository = FirebaseSmartInputRepository(
        aiRepository: _FakeAiRepository(),
        dataSource: dataSource,
      );

      final messages = await repository
          .watchSmartMessages(
            userId: const EntityId('user-1'),
            petId: const EntityId('pet-1'),
          )
          .first;

      expect(messages, [message]);
      expect(dataSource.watchedUserId, 'user-1');
      expect(dataSource.watchedPetId, 'pet-1');
    });

    test('gets a message through the Firestore data source', () async {
      final message = _message();
      final dataSource = _FakeFirestoreSmartInputDataSource(
        foundMessage: message,
      );
      final repository = FirebaseSmartInputRepository(
        aiRepository: _FakeAiRepository(),
        dataSource: dataSource,
      );

      final result = await repository.getSmartMessage(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        messageId: const EntityId('message-1'),
      );

      expect(result, message);
      expect(dataSource.getUserId, 'user-1');
      expect(dataSource.getPetId, 'pet-1');
      expect(dataSource.getMessageId, 'message-1');
    });

    test('saves confirmed messages through the Firestore data source',
        () async {
      final message = _message();
      final dataSource = _FakeFirestoreSmartInputDataSource();
      final repository = FirebaseSmartInputRepository(
        aiRepository: _FakeAiRepository(),
        dataSource: dataSource,
      );

      await repository.saveSmartMessage(message);

      expect(dataSource.savedMessage, message);
    });

    test('rejects unconfirmed messages before saving', () async {
      final dataSource = _FakeFirestoreSmartInputDataSource();
      final repository = FirebaseSmartInputRepository(
        aiRepository: _FakeAiRepository(),
        dataSource: dataSource,
      );

      expect(
        () => repository.saveSmartMessage(
          _message(status: SmartMessageStatus.awaitingConfirmation),
        ),
        throwsA(isA<StateError>()),
      );
      expect(dataSource.savedMessage, isNull);
    });

    test('deletes a message through the Firestore data source', () async {
      final dataSource = _FakeFirestoreSmartInputDataSource();
      final repository = FirebaseSmartInputRepository(
        aiRepository: _FakeAiRepository(),
        dataSource: dataSource,
      );

      await repository.deleteSmartMessage(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        messageId: const EntityId('message-1'),
      );

      expect(dataSource.deletedUserId, 'user-1');
      expect(dataSource.deletedPetId, 'pet-1');
      expect(dataSource.deletedMessageId, 'message-1');
    });
  });
}

SmartInputDraft _draft() {
  return const SmartInputDraft(
    originalText: 'Add rabies vaccine.',
    requiresConfirmation: true,
    detectedIntent: SmartMessageIntent.addVaccination,
    confidence: 0.8,
  );
}

SmartMessage _message({
  SmartMessageStatus status = SmartMessageStatus.confirmed,
}) {
  return SmartMessage(
    id: const EntityId('message-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    originalText: 'Add rabies vaccine.',
    detectedIntent: SmartMessageIntent.addVaccination,
    confidence: 0.8,
    status: status,
  );
}

class _FakeAiRepository implements AiRepository {
  _FakeAiRepository({SmartInputDraft? draft}) : draft = draft ?? _draft();

  final SmartInputDraft draft;

  String? structuredUserInput;

  @override
  Future<SmartInputDraft> structureDocumentText(String text) async {
    return draft;
  }

  @override
  Future<SmartInputDraft> structureUserInput(String input) async {
    structuredUserInput = input;
    return draft;
  }
}

class _FakeFirestoreSmartInputDataSource
    implements FirestoreSmartInputDataSource {
  _FakeFirestoreSmartInputDataSource({
    this.watchedMessages = const [],
    this.foundMessage,
  });

  final List<SmartMessage> watchedMessages;
  final SmartMessage? foundMessage;

  String? watchedUserId;
  String? watchedPetId;
  String? getUserId;
  String? getPetId;
  String? getMessageId;
  SmartMessage? savedMessage;
  String? deletedUserId;
  String? deletedPetId;
  String? deletedMessageId;

  @override
  Future<void> deleteSmartMessage({
    required String userId,
    required String petId,
    required String messageId,
  }) async {
    deletedUserId = userId;
    deletedPetId = petId;
    deletedMessageId = messageId;
  }

  @override
  Future<SmartMessage?> getSmartMessage({
    required String userId,
    required String petId,
    required String messageId,
  }) async {
    getUserId = userId;
    getPetId = petId;
    getMessageId = messageId;
    return foundMessage;
  }

  @override
  Future<void> saveSmartMessage(SmartMessage message) async {
    savedMessage = message;
  }

  @override
  Stream<List<SmartMessage>> watchSmartMessages({
    required String userId,
    required String petId,
  }) {
    watchedUserId = userId;
    watchedPetId = petId;
    return Stream<List<SmartMessage>>.value(watchedMessages);
  }
}
