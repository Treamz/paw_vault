import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_input_draft.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';
import 'package:paw_vault/features/smart_input/domain/repositories/smart_input_repository.dart';
import 'package:paw_vault/features/smart_input/presentation/cubit/smart_input_cubit.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';

void main() {
  group('SmartInputCubit', () {
    test('submits text and emits the AI draft for review', () async {
      final draft = _draft();
      final repository = _FakeSmartInputRepository(draft: draft);
      final cubit = _cubit(repository);
      final states = <SmartInputState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.submit('Bella got her rabies shot today');
      await Future<void>.delayed(Duration.zero);

      expect(repository.createDraftInput, 'Bella got her rabies shot today');
      expect(states.first.status, SmartInputStatus.processing);
      expect(states.last.status, SmartInputStatus.review);
      expect(states.last.draft, draft);
      expect(states.last.hasDraft, isTrue);

      await subscription.cancel();
      await cubit.close();
    });

    test('rejects empty input without calling the repository', () async {
      final repository = _FakeSmartInputRepository(draft: _draft());
      final cubit = _cubit(repository);

      await cubit.submit('   ');

      expect(cubit.state.status, SmartInputStatus.failure);
      expect(repository.createDraftCallCount, isZero);

      await cubit.close();
    });

    test('emits failure when the AI repository throws', () async {
      final repository = _FakeSmartInputRepository(throwsOnCreate: true);
      final cubit = _cubit(repository);

      await cubit.submit('Bella got her rabies shot today');

      expect(cubit.state.status, SmartInputStatus.failure);
      expect(cubit.state.errorMessage, contains('ai failed'));

      await cubit.close();
    });

    test('confirmDraft saves the reviewed draft as a confirmed message',
        () async {
      final repository = _FakeSmartInputRepository(draft: _draft());
      final cubit = _cubit(repository);

      await cubit.submit('Bella got her rabies shot today');
      await cubit.confirmDraft('pet-1');

      final saved = repository.savedMessage;
      expect(saved, isNotNull);
      expect(saved!.status, SmartMessageStatus.confirmed);
      expect(saved.petId, const EntityId('pet-1'));
      expect(saved.userId, const EntityId('user-1'));
      expect(saved.detectedIntent, SmartMessageIntent.addVaccination);
      expect(saved.originalText, 'Bella got her rabies shot today');
      expect(cubit.state.status, SmartInputStatus.confirmed);
      expect(cubit.state.hasDraft, isFalse);

      await cubit.close();
    });

    test('confirmDraft persists user-edited extracted details', () async {
      final repository = _FakeSmartInputRepository(draft: _draft());
      final cubit = _cubit(repository);

      await cubit.submit('Bella is sneezing');
      await cubit.confirmDraft(
        'pet-1',
        extractedData: const {'symptom': 'sneezing', 'since': 'yesterday'},
      );

      final saved = repository.savedMessage;
      expect(saved, isNotNull);
      expect(saved!.extractedData['symptom'], 'sneezing');
      expect(saved.extractedData['since'], 'yesterday');

      await cubit.close();
    });

    test('confirmDraft does nothing when there is no draft', () async {
      final repository = _FakeSmartInputRepository(draft: _draft());
      final cubit = _cubit(repository);

      await cubit.confirmDraft('pet-1');

      expect(repository.saveCallCount, isZero);
      expect(cubit.state.status, SmartInputStatus.failure);

      await cubit.close();
    });

    test('load emits the watched smart messages as history', () async {
      final message = _message();
      final repository = _FakeSmartInputRepository(watchedMessages: [message]);
      final cubit = _cubit(repository);

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.historyStatus, SmartHistoryStatus.ready);
      expect(cubit.state.messages, [message]);

      await cubit.close();
    });

    test('load emits history failure when the stream errors', () async {
      final repository = _FakeSmartInputRepository(throwsOnWatch: true);
      final cubit = _cubit(repository);

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.historyStatus, SmartHistoryStatus.failure);
      expect(cubit.state.historyError, contains('watch failed'));

      await cubit.close();
    });

    test('dismissDraft clears the draft without saving', () async {
      final repository = _FakeSmartInputRepository(draft: _draft());
      final cubit = _cubit(repository);

      await cubit.submit('Bella got her rabies shot today');
      expect(cubit.state.hasDraft, isTrue);

      cubit.dismissDraft();

      expect(cubit.state.status, SmartInputStatus.idle);
      expect(cubit.state.draft, isNull);
      expect(repository.saveCallCount, isZero);

      await cubit.close();
    });

    test('confirmDraft emits failure when saving throws', () async {
      final repository = _FakeSmartInputRepository(
        draft: _draft(),
        throwsOnSave: true,
      );
      final cubit = _cubit(repository);

      await cubit.submit('Bella got her rabies shot today');
      await cubit.confirmDraft('pet-1');

      expect(cubit.state.status, SmartInputStatus.failure);
      // The draft is preserved so the user can retry confirming.
      expect(cubit.state.draft, isNotNull);

      await cubit.close();
    });

    test('createTimelineEventFromMessage saves an event and returns its id',
        () async {
      final timeline = _FakeTimelineRepository();
      final cubit = _cubit(
        _FakeSmartInputRepository(draft: _draft()),
        timelineRepository: timeline,
      );

      const message = SmartMessage(
        id: EntityId('msg-1'),
        userId: EntityId('user-1'),
        petId: EntityId('pet-1'),
        originalText: 'Bella got her rabies shot today',
        detectedIntent: SmartMessageIntent.addVaccination,
        extractedData: {'vaccine': 'rabies'},
        confidence: 0.92,
        status: SmartMessageStatus.confirmed,
      );

      final eventId = await cubit.createTimelineEventFromMessage(message);

      expect(eventId, isNotNull);
      final saved = timeline.savedEvent;
      expect(saved, isNotNull);
      expect(saved!.id.value, eventId);
      expect(saved.petId, const EntityId('pet-1'));
      expect(saved.userId, const EntityId('user-1'));
      expect(saved.type, PetEventType.vaccination);
      expect(saved.source, PetEventSource.smartText);
      expect(saved.description, contains('vaccine: rabies'));

      await cubit.close();
    });

    test('createTimelineEventFromMessage returns null without a repository',
        () async {
      final cubit = _cubit(_FakeSmartInputRepository(draft: _draft()));

      final eventId = await cubit.createTimelineEventFromMessage(_message());

      expect(eventId, isNull);

      await cubit.close();
    });
  });
}

class _FakeTimelineRepository implements TimelineRepository {
  PetEvent? savedEvent;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveEvent(PetEvent event) async {
    savedEvent = event;
  }

  @override
  Future<PetEvent?> getEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async =>
      null;

  @override
  Future<void> deleteEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async {}

  @override
  Stream<List<PetEvent>> watchEvents({
    required EntityId userId,
    required EntityId petId,
  }) =>
      const Stream<List<PetEvent>>.empty();
}

SmartInputCubit _cubit(
  _FakeSmartInputRepository repository, {
  TimelineRepository? timelineRepository,
}) {
  return SmartInputCubit(
    smartInputRepository: repository,
    authRepository: _FakeAuthRepository(
      currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
    ),
    timelineRepository: timelineRepository,
  );
}

SmartInputDraft _draft() {
  return const SmartInputDraft(
    originalText: 'Bella got her rabies shot today',
    requiresConfirmation: true,
    detectedIntent: SmartMessageIntent.addVaccination,
    confidence: 0.92,
  );
}

SmartMessage _message() {
  return const SmartMessage(
    id: EntityId('msg-1'),
    userId: EntityId('user-1'),
    petId: EntityId('pet-1'),
    originalText: 'Bella got her rabies shot today',
    detectedIntent: SmartMessageIntent.addVaccination,
    confidence: 0.92,
    status: SmartMessageStatus.confirmed,
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.currentUserValue});

  final AppUser? currentUserValue;

  @override
  Future<AppUser?> currentUser() async => currentUserValue;

  @override
  Future<AppUser> signInAnonymously() async =>
      const AppUser(id: 'signed-in-user', isAnonymous: true);

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() =>
      Stream<AppUser?>.value(currentUserValue);
}

class _FakeSmartInputRepository implements SmartInputRepository {
  _FakeSmartInputRepository({
    this.draft,
    this.throwsOnCreate = false,
    this.throwsOnSave = false,
    this.watchedMessages = const [],
    this.throwsOnWatch = false,
  });

  final SmartInputDraft? draft;
  final bool throwsOnCreate;
  final bool throwsOnSave;
  final List<SmartMessage> watchedMessages;
  final bool throwsOnWatch;

  int createDraftCallCount = 0;
  String? createDraftInput;
  int saveCallCount = 0;
  SmartMessage? savedMessage;

  @override
  Future<SmartInputDraft> createDraft(String input) async {
    createDraftCallCount++;
    createDraftInput = input;
    if (throwsOnCreate) {
      throw StateError('ai failed');
    }
    return draft!;
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
  Future<void> saveSmartMessage(SmartMessage message) async {
    saveCallCount++;
    if (throwsOnSave) {
      throw StateError('save failed');
    }
    savedMessage = message;
  }

  @override
  Stream<List<SmartMessage>> watchSmartMessages({
    required EntityId userId,
    required EntityId petId,
  }) {
    if (throwsOnWatch) {
      return Stream<List<SmartMessage>>.error(StateError('watch failed'));
    }
    return Stream<List<SmartMessage>>.value(watchedMessages);
  }
}
