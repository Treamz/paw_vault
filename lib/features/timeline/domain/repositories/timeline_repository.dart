import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';

abstract interface class TimelineRepository {
  Future<void> initialize();

  Stream<List<PetEvent>> watchEvents({
    required EntityId userId,
    required EntityId petId,
  });

  Future<PetEvent?> getEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  });

  Future<void> saveEvent(PetEvent event);

  Future<void> deleteEvent({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
  });
}
