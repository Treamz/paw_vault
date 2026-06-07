import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/timeline/data/datasources/firestore_timeline_data_source.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';

class FirebaseTimelineRepository implements TimelineRepository {
  const FirebaseTimelineRepository(this._dataSource);

  final FirestoreTimelineDataSource _dataSource;

  @override
  Future<void> deleteEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) {
    return _dataSource.deleteEvent(
      userId: userId.value,
      petId: petId.value,
      eventId: eventId.value,
    );
  }

  @override
  Future<PetEvent?> getEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  }) {
    return _dataSource.getEvent(
      userId: userId.value,
      petId: petId.value,
      eventId: eventId.value,
    );
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveEvent(PetEvent event) {
    return _dataSource.saveEvent(event);
  }

  @override
  Stream<List<PetEvent>> watchEvents({
    required EntityId userId,
    required EntityId petId,
  }) {
    return _dataSource.watchEvents(
      userId: userId.value,
      petId: petId.value,
    );
  }
}
