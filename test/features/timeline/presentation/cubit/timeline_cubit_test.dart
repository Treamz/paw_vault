import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:paw_vault/features/timeline/presentation/cubit/timeline_cubit.dart';

void main() {
  group('TimelineCubit', () {
    test('loads the current user and emits watched events', () async {
      final event = _event();
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository =
          _FakeTimelineRepository(watchedEvents: [event]);
      final cubit = TimelineCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );
      final states = <TimelineState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(timelineRepository.initializeCallCount, 1);
      expect(authRepository.currentUserCallCount, 1);
      expect(authRepository.signInAnonymouslyCallCount, isZero);
      expect(timelineRepository.watchedUserId, const EntityId('user-1'));
      expect(timelineRepository.watchedPetId, const EntityId('pet-1'));
      expect(states.first.status, TimelineStatus.loading);
      expect(states.last.status, TimelineStatus.ready);
      expect(states.last.userId, const EntityId('user-1'));
      expect(states.last.petId, 'pet-1');
      expect(states.last.events, [event]);

      await subscription.cancel();
      await cubit.close();
    });

    test('signs in anonymously when no current user exists', () async {
      final authRepository = _FakeAuthRepository(
        signedInUser: const AppUser(id: 'anonymous-user', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository();
      final cubit = TimelineCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(authRepository.currentUserCallCount, 1);
      expect(authRepository.signInAnonymouslyCallCount, 1);
      expect(
          timelineRepository.watchedUserId, const EntityId('anonymous-user'));
      expect(timelineRepository.watchedPetId, const EntityId('pet-1'));
      expect(cubit.state.status, TimelineStatus.ready);

      await cubit.close();
    });

    test('emits failure when loading throws', () async {
      final authRepository = _FakeAuthRepository();
      final timelineRepository =
          _FakeTimelineRepository(throwsOnInitialize: true);
      final cubit = TimelineCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1');

      expect(cubit.state.status, TimelineStatus.failure);
      expect(cubit.state.petId, 'pet-1');
      expect(cubit.state.errorMessage, contains('initialize failed'));

      await cubit.close();
    });

    test('emits empty list when no events exist', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository = _FakeTimelineRepository(watchedEvents: []);
      final cubit = TimelineCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, TimelineStatus.ready);
      expect(cubit.state.events, isEmpty);

      await cubit.close();
    });

    test('emits failure when stream emits error', () async {
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository =
          _FakeTimelineRepository(throwsOnWatch: true);
      final cubit = TimelineCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );
      final states = <TimelineState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(states.last.status, TimelineStatus.failure);
      expect(states.last.errorMessage, contains('watch failed'));

      await subscription.cancel();
      await cubit.close();
    });

    test('filters events by event type', () async {
      final event1 = _event(type: PetEventType.vaccination);
      final event2 = _event(type: PetEventType.vetVisit);
      final event3 = _event(type: PetEventType.vaccination);
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository =
          _FakeTimelineRepository(watchedEvents: [event1, event2, event3]);
      final cubit = TimelineCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.events.length, 3);
      expect(cubit.state.filteredEvents.length, 3);

      cubit.setEventTypeFilter(PetEventType.vaccination);

      expect(cubit.state.filteredEvents.length, 2);
      expect(cubit.state.filteredEvents.every((e) => e.type == PetEventType.vaccination), isTrue);

      await cubit.close();
    });

    test('filters events by date range', () async {
      final event1 =
          _event(date: UtcDateTime(DateTime(2024, 1, 1)));
      final event2 =
          _event(date: UtcDateTime(DateTime(2024, 2, 15)));
      final event3 =
          _event(date: UtcDateTime(DateTime(2024, 3, 30)));
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository =
          _FakeTimelineRepository(watchedEvents: [event1, event2, event3]);
      final cubit = TimelineCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.events.length, 3);
      expect(cubit.state.filteredEvents.length, 3);

      cubit.setDateRangeFilter(
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 3, 1),
      );

      expect(cubit.state.filteredEvents.length, 1);
      expect(cubit.state.filteredEvents.first, event2);

      await cubit.close();
    });

    test('filters events by both type and date range', () async {
      final event1 = _event(
        type: PetEventType.vaccination,
        date: UtcDateTime(DateTime(2024, 1, 15)),
      );
      final event2 = _event(
        type: PetEventType.vetVisit,
        date: UtcDateTime(DateTime(2024, 2, 15)),
      );
      final event3 = _event(
        type: PetEventType.vaccination,
        date: UtcDateTime(DateTime(2024, 2, 20)),
      );
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository =
          _FakeTimelineRepository(watchedEvents: [event1, event2, event3]);
      final cubit = TimelineCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      cubit.setEventTypeFilter(PetEventType.vaccination);
      cubit.setDateRangeFilter(
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 3, 1),
      );

      expect(cubit.state.filteredEvents.length, 1);
      expect(cubit.state.filteredEvents.first, event3);

      await cubit.close();
    });

    test('clears all filters', () async {
      final event1 = _event(type: PetEventType.vaccination);
      final event2 = _event(type: PetEventType.vetVisit);
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final timelineRepository =
          _FakeTimelineRepository(watchedEvents: [event1, event2]);
      final cubit = TimelineCubit(
        timelineRepository: timelineRepository,
        authRepository: authRepository,
      );

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      cubit.setEventTypeFilter(PetEventType.vaccination);
      cubit.setDateRangeFilter(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      expect(cubit.state.filterEventType, PetEventType.vaccination);
      expect(cubit.state.filterStartDate, isNotNull);
      expect(cubit.state.filterEndDate, isNotNull);

      cubit.clearFilters();

      expect(cubit.state.filterEventType, isNull);
      expect(cubit.state.filterStartDate, isNull);
      expect(cubit.state.filterEndDate, isNull);
      expect(cubit.state.filteredEvents.length, 2);

      await cubit.close();
    });
  });
}

PetEvent _event({
  PetEventType type = PetEventType.vaccination,
  UtcDateTime? date,
}) {
  return PetEvent(
    id: const EntityId('event-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    type: type,
    title: 'Annual vaccination',
    date: date ?? UtcDateTime(DateTime(2024, 1, 15)),
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
    this.watchedEvents = const [],
    this.throwsOnInitialize = false,
    this.throwsOnWatch = false,
  });

  final List<PetEvent> watchedEvents;
  final bool throwsOnInitialize;
  final bool throwsOnWatch;

  int initializeCallCount = 0;
  EntityId? watchedUserId;
  EntityId? watchedPetId;

  @override
  Future<void> deleteEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async {}

  @override
  Future<PetEvent?> getEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) async {
    return null;
  }

  @override
  Future<void> initialize() async {
    initializeCallCount++;
    if (throwsOnInitialize) {
      throw StateError('initialize failed');
    }
  }

  @override
  Future<void> saveEvent(PetEvent event) async {}

  @override
  Stream<List<PetEvent>> watchEvents({
    required EntityId userId,
    required EntityId petId,
  }) {
    watchedUserId = userId;
    watchedPetId = petId;
    if (throwsOnWatch) {
      return Stream<List<PetEvent>>.error(StateError('watch failed'));
    }
    return Stream<List<PetEvent>>.value(watchedEvents);
  }
}
