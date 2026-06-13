import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/timeline/presentation/cubit/timeline_event_cubit.dart';
import 'package:paw_vault/features/timeline/presentation/models/pet_event_form_state.dart';

void main() {
  group('TimelineEventCubit', () {
    test('loads the current user and fetches the requested event', () async {
      final event = _event();
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository(event: event);
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );
      final states = <TimelineEventState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.load('pet-1', 'event-1');
      await Future<void>.delayed(Duration.zero);

      expect(timelineRepository.initializeCallCount, 1);
      expect(authRepository.currentUserCallCount, 1);
      expect(authRepository.signInAnonymouslyCallCount, isZero);
      expect(timelineRepository.requestedUserId, const EntityId('user-1'));
      expect(timelineRepository.requestedPetId, const EntityId('pet-1'));
      expect(timelineRepository.requestedEventId, const EntityId('event-1'));
      expect(states.first.status, TimelineEventStatus.loading);
      expect(states.last.status, TimelineEventStatus.ready);
      expect(states.last.userId, const EntityId('user-1'));
      expect(states.last.petId, 'pet-1');
      expect(states.last.eventId, 'event-1');
      expect(states.last.event, event);
      expect(states.last.isReady, isTrue);

      await subscription.cancel();
      await cubit.close();
    });

    test('signs in anonymously when no current user exists', () async {
      final event = _event(userId: const EntityId('anonymous-user'));
      final authRepository = _FakeAuthRepository(
        signedInUser: const AppUser(id: 'anonymous-user', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository(event: event);
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1', 'event-1');

      expect(authRepository.currentUserCallCount, 1);
      expect(authRepository.signInAnonymouslyCallCount, 1);
      expect(
        timelineRepository.requestedUserId,
        const EntityId('anonymous-user'),
      );
      expect(cubit.state.status, TimelineEventStatus.ready);

      await cubit.close();
    });

    test('emits notFound when repository returns no event', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository();
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1', 'missing-event');

      expect(cubit.state.status, TimelineEventStatus.notFound);
      expect(cubit.state.userId, const EntityId('user-1'));
      expect(cubit.state.petId, 'pet-1');
      expect(cubit.state.eventId, 'missing-event');
      expect(cubit.state.event, isNull);
      expect(cubit.state.isReady, isFalse);

      await cubit.close();
    });

    test('emits failure when loading throws', () async {
      final authRepository = _FakeAuthRepository();
      final timelineRepository =
          _FakeTimelineRepository(throwsOnInitialize: true);
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1', 'event-1');

      expect(cubit.state.status, TimelineEventStatus.failure);
      expect(cubit.state.petId, 'pet-1');
      expect(cubit.state.eventId, 'event-1');
      expect(cubit.state.errorMessage, contains('initialize failed'));

      await cubit.close();
    });

    test('creates a new event from form state', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository();
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Annual vaccination',
        date: DateTime(2024, 1, 15),
        description: 'Rabies shot',
      );
      final states = <TimelineEventState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.createEvent('pet-1', formState);
      await Future<void>.delayed(Duration.zero);

      expect(timelineRepository.initializeCallCount, 1);
      expect(timelineRepository.saveEventCallCount, 1);
      expect(timelineRepository.savedEvent, isNotNull);
      expect(timelineRepository.savedEvent!.type, PetEventType.vaccination);
      expect(timelineRepository.savedEvent!.title, 'Annual vaccination');
      expect(timelineRepository.savedEvent!.description, 'Rabies shot');
      expect(timelineRepository.savedEvent!.userId, const EntityId('user-1'));
      expect(timelineRepository.savedEvent!.petId, const EntityId('pet-1'));
      expect(states.first.status, TimelineEventStatus.saving);
      expect(states.last.status, TimelineEventStatus.ready);
      expect(states.last.event, timelineRepository.savedEvent);
      expect(states.last.userId, const EntityId('user-1'));
      expect(states.last.petId, 'pet-1');
      expect(states.last.eventId, isNotEmpty);

      await subscription.cancel();
      await cubit.close();
    });

    test('creates event with anonymous user when no current user', () async {
      final authRepository = _FakeAuthRepository(
        signedInUser: const AppUser(id: 'anon-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository();
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );
      final formState = PetEventFormState(
        type: PetEventType.vetVisit,
        title: 'Vet checkup',
        date: DateTime(2024, 1, 15),
      );

      await cubit.createEvent('pet-1', formState);

      expect(authRepository.signInAnonymouslyCallCount, 1);
      expect(timelineRepository.savedEvent!.userId, const EntityId('anon-1'));
      expect(cubit.state.status, TimelineEventStatus.ready);

      await cubit.close();
    });

    test('emits failure when create throws', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository(throwsOnSave: true);
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Vaccination',
        date: DateTime(2024, 1, 15),
      );

      await cubit.createEvent('pet-1', formState);

      expect(cubit.state.status, TimelineEventStatus.failure);
      expect(cubit.state.errorMessage, contains('save failed'));

      await cubit.close();
    });

    test('updates an existing event from form state', () async {
      final existingEvent = PetEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        type: PetEventType.vaccination,
        title: 'Old title',
        date: UtcDateTime(DateTime(2024, 1, 15)),
        source: PetEventSource.manual,
      );
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository(event: existingEvent);
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1', 'event-1');

      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Updated title',
        date: DateTime(2024, 1, 15),
        description: 'New description',
      );
      final states = <TimelineEventState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.updateEvent(formState);
      await Future<void>.delayed(Duration.zero);

      expect(timelineRepository.saveEventCallCount, 1);
      expect(timelineRepository.savedEvent, isNotNull);
      expect(timelineRepository.savedEvent!.id, const EntityId('event-1'));
      expect(timelineRepository.savedEvent!.userId, const EntityId('user-1'));
      expect(timelineRepository.savedEvent!.petId, const EntityId('pet-1'));
      expect(timelineRepository.savedEvent!.title, 'Updated title');
      expect(timelineRepository.savedEvent!.description, 'New description');
      expect(states.first.status, TimelineEventStatus.saving);
      expect(states.last.status, TimelineEventStatus.ready);
      expect(states.last.event!.title, 'Updated title');

      await subscription.cancel();
      await cubit.close();
    });

    test('emits failure when updating with no loaded event', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository();
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );
      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Title',
        date: DateTime(2024, 1, 15),
      );

      await cubit.updateEvent(formState);

      expect(cubit.state.status, TimelineEventStatus.failure);
      expect(
        cubit.state.errorMessage,
        contains('Cannot update: no event loaded'),
      );
      expect(timelineRepository.saveEventCallCount, isZero);

      await cubit.close();
    });

    test('emits failure when update throws', () async {
      final existingEvent = PetEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        type: PetEventType.vaccination,
        title: 'Old title',
        date: UtcDateTime(DateTime(2024, 1, 15)),
        source: PetEventSource.manual,
      );
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository(
        event: existingEvent,
        throwsOnSave: true,
      );
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1', 'event-1');

      final formState = PetEventFormState(
        type: PetEventType.vaccination,
        title: 'Updated title',
        date: DateTime(2024, 1, 15),
      );

      await cubit.updateEvent(formState);

      expect(cubit.state.status, TimelineEventStatus.failure);
      expect(cubit.state.errorMessage, contains('save failed'));

      await cubit.close();
    });

    test('deletes an existing event', () async {
      final existingEvent = PetEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        type: PetEventType.vaccination,
        title: 'Event to delete',
        date: UtcDateTime(DateTime(2024, 1, 15)),
        source: PetEventSource.manual,
      );
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository(event: existingEvent);
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1', 'event-1');

      final states = <TimelineEventState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.deleteEvent();
      await Future<void>.delayed(Duration.zero);

      expect(timelineRepository.deleteEventCallCount, 1);
      expect(timelineRepository.deletedUserId, const EntityId('user-1'));
      expect(timelineRepository.deletedPetId, const EntityId('pet-1'));
      expect(timelineRepository.deletedEventId, const EntityId('event-1'));
      expect(states.first.status, TimelineEventStatus.deleting);
      expect(states.last.status, TimelineEventStatus.ready);
      expect(states.last.event, isNull);

      await subscription.cancel();
      await cubit.close();
    });

    test('emits failure when deleting with no loaded event', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository();
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );

      await cubit.deleteEvent();

      expect(cubit.state.status, TimelineEventStatus.failure);
      expect(
        cubit.state.errorMessage,
        contains('Cannot delete: no event loaded'),
      );
      expect(timelineRepository.deleteEventCallCount, isZero);

      await cubit.close();
    });

    test('emits failure when delete throws', () async {
      final existingEvent = PetEvent(
        id: const EntityId('event-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        type: PetEventType.vaccination,
        title: 'Event to delete',
        date: UtcDateTime(DateTime(2024, 1, 15)),
        source: PetEventSource.manual,
      );
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository(
        event: existingEvent,
        throwsOnDelete: true,
      );
      final cubit = TimelineEventCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1', 'event-1');

      await cubit.deleteEvent();

      expect(cubit.state.status, TimelineEventStatus.failure);
      expect(cubit.state.errorMessage, contains('delete failed'));

      await cubit.close();
    });
  });
}

PetEvent _event({
  EntityId userId = const EntityId('user-1'),
}) {
  return PetEvent(
    id: const EntityId('event-1'),
    userId: userId,
    petId: const EntityId('pet-1'),
    type: PetEventType.vaccination,
    title: 'Annual vaccination',
    date: UtcDateTime(DateTime(2024, 1, 15)),
    source: PetEventSource.manual,
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.currentUserValue,
    this.signedInUser = const AppUser(id: 'signed-in-user', isAnonymous: true),
  });

  final AppUser? currentUserValue;
  final AppUser signedInUser;

  int currentUserCallCount = 0;
  int signInAnonymouslyCallCount = 0;

  @override
  Future<AppUser?> currentUser() async {
    currentUserCallCount++;
    return currentUserValue;
  }

  @override
  Future<AppUser> signInAnonymously() async {
    signInAnonymouslyCallCount++;
    return signedInUser;
  }

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() {
    return Stream<AppUser?>.value(currentUserValue);
  }
}

class _FakeTimelineRepository implements TimelineRepository {
  _FakeTimelineRepository({
    this.event,
    this.throwsOnInitialize = false,
    this.throwsOnSave = false,
    this.throwsOnDelete = false,
  });

  final PetEvent? event;
  final bool throwsOnInitialize;
  final bool throwsOnSave;
  final bool throwsOnDelete;

  int initializeCallCount = 0;
  int saveEventCallCount = 0;
  int deleteEventCallCount = 0;
  EntityId? requestedUserId;
  EntityId? requestedPetId;
  EntityId? requestedEventId;
  EntityId? deletedUserId;
  EntityId? deletedPetId;
  EntityId? deletedEventId;
  PetEvent? savedEvent;

  @override
  Future<void> deleteEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async {
    deleteEventCallCount++;
    deletedUserId = userId;
    deletedPetId = petId;
    deletedEventId = eventId;
    if (throwsOnDelete) {
      throw StateError('delete failed');
    }
  }

  @override
  Future<PetEvent?> getEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async {
    requestedUserId = userId;
    requestedPetId = petId;
    requestedEventId = eventId;
    return event;
  }

  @override
  Future<void> initialize() async {
    initializeCallCount++;
    if (throwsOnInitialize) {
      throw StateError('initialize failed');
    }
  }

  @override
  Future<void> saveEvent(PetEvent event) async {
    saveEventCallCount++;
    if (throwsOnSave) {
      throw StateError('save failed');
    }
    savedEvent = event;
  }

  @override
  Stream<List<PetEvent>> watchEvents({
    required EntityId userId,
    required EntityId petId,
  }) {
    return Stream<List<PetEvent>>.value(const []);
  }
}
