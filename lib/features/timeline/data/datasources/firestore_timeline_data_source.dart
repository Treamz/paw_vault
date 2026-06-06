import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';

abstract interface class FirestoreTimelineDataSource {
  Stream<List<PetEvent>> watchEvents({
    required String userId,
    required String petId,
  });
}
