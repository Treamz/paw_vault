import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';
import 'package:paw_vault/features/smart_input/data/datasources/firestore_smart_input_data_source.dart';
import 'package:paw_vault/features/smart_input/data/mappers/smart_message_firestore_mapper.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';

class FlutterFireSmartInputDataSource implements FirestoreSmartInputDataSource {
  FlutterFireSmartInputDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> deleteSmartMessage({
    required String userId,
    required String petId,
    required String messageId,
  }) async {
    await _smartMessageDocument(
      userId: userId,
      petId: petId,
      messageId: messageId,
    ).delete();
  }

  @override
  Future<SmartMessage?> getSmartMessage({
    required String userId,
    required String petId,
    required String messageId,
  }) async {
    final snapshot = await _smartMessageDocument(
      userId: userId,
      petId: petId,
      messageId: messageId,
    ).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return SmartMessageFirestoreMapper.fromFirestore(
      id: EntityId(snapshot.id),
      data: data,
    );
  }

  @override
  Future<void> saveSmartMessage(SmartMessage message) async {
    final document = _smartMessageDocument(
      userId: message.userId.value,
      petId: message.petId.value,
      messageId: message.id.value,
    );
    final snapshot = await document.get();
    final data = SmartMessageFirestoreMapper.toFirestore(message)
      ..remove('createdAt');

    if (!snapshot.exists) {
      data['createdAt'] = FirestoreMapping.serverTimestamp();
    }

    await document.set(data, SetOptions(merge: true));
  }

  @override
  Stream<List<SmartMessage>> watchSmartMessages({
    required String userId,
    required String petId,
  }) {
    return _firestore
        .collection(FirestorePaths.smartMessages(userId: userId, petId: petId))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => SmartMessageFirestoreMapper.fromFirestore(
                  id: EntityId(document.id),
                  data: document.data(),
                ),
              )
              .toList(),
        );
  }

  DocumentReference<Map<String, Object?>> _smartMessageDocument({
    required String userId,
    required String petId,
    required String messageId,
  }) {
    return _firestore.doc(
      '${FirestorePaths.smartMessages(userId: userId, petId: petId)}/$messageId',
    );
  }
}
