import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';
import 'package:paw_vault/features/documents/data/datasources/firestore_document_data_source.dart';
import 'package:paw_vault/features/documents/data/mappers/pet_document_firestore_mapper.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';

class FlutterFireDocumentDataSource implements FirestoreDocumentDataSource {
  FlutterFireDocumentDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> deleteDocument({
    required String userId,
    required String petId,
    required String documentId,
  }) async {
    await _documentDocument(
      userId: userId,
      petId: petId,
      documentId: documentId,
    ).delete();
  }

  @override
  Future<PetDocument?> getDocument({
    required String userId,
    required String petId,
    required String documentId,
  }) async {
    final snapshot = await _documentDocument(
      userId: userId,
      petId: petId,
      documentId: documentId,
    ).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return PetDocumentFirestoreMapper.fromFirestore(
      id: EntityId(snapshot.id),
      data: data,
    );
  }

  @override
  Future<void> saveDocument(PetDocument document) async {
    final documentReference = _documentDocument(
      userId: document.userId.value,
      petId: document.petId.value,
      documentId: document.id.value,
    );
    final snapshot = await documentReference.get();
    final data = PetDocumentFirestoreMapper.toFirestore(document)
      ..remove('createdAt')
      ..remove('updatedAt')
      ..['updatedAt'] = FirestoreMapping.serverTimestamp();

    if (!snapshot.exists) {
      data['createdAt'] = FirestoreMapping.serverTimestamp();
    }

    await documentReference.set(data, SetOptions(merge: true));
  }

  @override
  Stream<List<PetDocument>> watchDocuments({
    required String userId,
    required String petId,
  }) {
    return _firestore
        .collection(FirestorePaths.documents(userId: userId, petId: petId))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => PetDocumentFirestoreMapper.fromFirestore(
                  id: EntityId(document.id),
                  data: document.data(),
                ),
              )
              .toList(),
        );
  }

  DocumentReference<Map<String, Object?>> _documentDocument({
    required String userId,
    required String petId,
    required String documentId,
  }) {
    return _firestore.doc(
      '${FirestorePaths.documents(userId: userId, petId: petId)}/$documentId',
    );
  }
}
