import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';
import 'package:paw_vault/features/timeline/data/datasources/firestore_timeline_data_source.dart';
import 'package:paw_vault/features/timeline/data/mappers/pet_event_firestore_mapper.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';

class FlutterFireTimelineDataSource implements FirestoreTimelineDataSource {
  FlutterFireTimelineDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> deleteEvent({
    required String userId,
    required String petId,
    required String eventId,
  }) async {
    await _eventDocument(
      userId: userId,
      petId: petId,
      eventId: eventId,
    ).delete();
  }

  @override
  Future<PetEvent?> getEvent({
    required String userId,
    required String petId,
    required String eventId,
  }) async {
    final snapshot = await _eventDocument(
      userId: userId,
      petId: petId,
      eventId: eventId,
    ).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return PetEventFirestoreMapper.fromFirestore(
      id: EntityId(snapshot.id),
      data: data,
    );
  }

  @override
  Future<void> saveEvent(PetEvent event) async {
    final document = _eventDocument(
      userId: event.userId.value,
      petId: event.petId.value,
      eventId: event.id.value,
    );
    final snapshot = await document.get();
    final data = PetEventFirestoreMapper.toFirestore(event)
      ..remove('createdAt')
      ..remove('updatedAt')
      ..['updatedAt'] = FirestoreMapping.serverTimestamp();

    if (!snapshot.exists) {
      data['createdAt'] = FirestoreMapping.serverTimestamp();
    }

    await document.set(data, SetOptions(merge: true));
  }

  @override
  Stream<List<PetEvent>> watchEvents({
    required String userId,
    required String petId,
  }) {
    return _firestore
        .collection(FirestorePaths.events(userId: userId, petId: petId))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => PetEventFirestoreMapper.fromFirestore(
                  id: EntityId(document.id),
                  data: document.data(),
                ),
              )
              .toList(),
        );
  }

  DocumentReference<Map<String, Object?>> _eventDocument({
    required String userId,
    required String petId,
    required String eventId,
  }) {
    return _firestore.doc(
      '${FirestorePaths.events(userId: userId, petId: petId)}/$eventId',
    );
  }
}
