import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/repositories/timeline_repository.dart';

class LocalTimelineRepository implements TimelineRepository {
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
  Future<void> initialize() async {}

  @override
  Future<void> saveEvent(PetEvent event) async {}

  @override
  Stream<List<PetEvent>> watchEvents({
    required EntityId userId,
    required EntityId petId,
  }) {
    return Stream<List<PetEvent>>.value(const []);
  }
}
