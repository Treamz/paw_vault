import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/timeline/data/datasources/firestore_timeline_data_source.dart';
import 'package:paw_vault/features/timeline/data/repositories/firebase_timeline_repository.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';

void main() {
  group('FirebaseTimelineRepository', () {
    test('watches events through the Firestore data source', () async {
      final event = _event();
      final dataSource = _FakeFirestoreTimelineDataSource(watchedEvents: [
        event,
      ]);
      final repository = FirebaseTimelineRepository(dataSource);

      final events = await repository
          .watchEvents(
            userId: const EntityId('user-1'),
            petId: const EntityId('pet-1'),
          )
          .first;

      expect(events, [event]);
      expect(dataSource.watchedUserId, 'user-1');
      expect(dataSource.watchedPetId, 'pet-1');
    });

    test('gets an event through the Firestore data source', () async {
      final event = _event();
      final dataSource = _FakeFirestoreTimelineDataSource(foundEvent: event);
      final repository = FirebaseTimelineRepository(dataSource);

      final result = await repository.getEvent(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        eventId: const EntityId('event-1'),
      );

      expect(result, event);
      expect(dataSource.getUserId, 'user-1');
      expect(dataSource.getPetId, 'pet-1');
      expect(dataSource.getEventId, 'event-1');
    });

    test('saves an event through the Firestore data source', () async {
      final event = _event();
      final dataSource = _FakeFirestoreTimelineDataSource();
      final repository = FirebaseTimelineRepository(dataSource);

      await repository.saveEvent(event);

      expect(dataSource.savedEvent, event);
    });

    test('deletes an event through the Firestore data source', () async {
      final dataSource = _FakeFirestoreTimelineDataSource();
      final repository = FirebaseTimelineRepository(dataSource);

      await repository.deleteEvent(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        eventId: const EntityId('event-1'),
      );

      expect(dataSource.deletedUserId, 'user-1');
      expect(dataSource.deletedPetId, 'pet-1');
      expect(dataSource.deletedEventId, 'event-1');
    });
  });
}

PetEvent _event() {
  return PetEvent(
    id: const EntityId('event-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    type: PetEventType.vetVisit,
    title: 'Annual checkup',
    date: UtcDateTime(DateTime.utc(2026, 1, 2, 3, 4)),
    source: PetEventSource.manual,
  );
}

class _FakeFirestoreTimelineDataSource implements FirestoreTimelineDataSource {
  _FakeFirestoreTimelineDataSource({
    this.watchedEvents = const [],
    this.foundEvent,
  });

  final List<PetEvent> watchedEvents;
  final PetEvent? foundEvent;

  String? watchedUserId;
  String? watchedPetId;
  String? getUserId;
  String? getPetId;
  String? getEventId;
  PetEvent? savedEvent;
  String? deletedUserId;
  String? deletedPetId;
  String? deletedEventId;

  @override
  Future<void> deleteEvent({
    required String userId,
    required String petId,
    required String eventId,
  }) async {
    deletedUserId = userId;
    deletedPetId = petId;
    deletedEventId = eventId;
  }

  @override
  Future<PetEvent?> getEvent({
    required String userId,
    required String petId,
    required String eventId,
  }) async {
    getUserId = userId;
    getPetId = petId;
    getEventId = eventId;
    return foundEvent;
  }

  @override
  Future<void> saveEvent(PetEvent event) async {
    savedEvent = event;
  }

  @override
  Stream<List<PetEvent>> watchEvents({
    required String userId,
    required String petId,
  }) {
    watchedUserId = userId;
    watchedPetId = petId;
    return Stream<List<PetEvent>>.value(watchedEvents);
  }
}
