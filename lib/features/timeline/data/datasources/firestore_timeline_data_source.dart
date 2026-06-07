import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';

abstract interface class FirestoreTimelineDataSource {
  Stream<List<PetEvent>> watchEvents({
    required String userId,
    required String petId,
  });

  Future<PetEvent?> getEvent({
    required String userId,
    required String petId,
    required String eventId,
  });

  Future<void> saveEvent(PetEvent event);

  Future<void> deleteEvent({
    required String userId,
    required String petId,
    required String eventId,
  });
}
