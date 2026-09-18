import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';
import 'package:paw_vault/features/paw_scan/data/datasources/firestore_paw_check_data_source.dart';
import 'package:paw_vault/features/paw_scan/data/mappers/paw_check_firestore_mapper.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';

class FlutterFirePawCheckDataSource implements FirestorePawCheckDataSource {
  FlutterFirePawCheckDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<PawCheck>> watchChecks({
    required String userId,
    required String petId,
  }) {
    return _firestore
        .collection(FirestorePaths.pawChecks(userId: userId, petId: petId))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => PawCheckFirestoreMapper.fromFirestore(
                  id: EntityId(document.id),
                  data: document.data(),
                ),
              )
              .toList(),
        );
  }

  @override
  Future<PawCheck?> getCheck({
    required String userId,
    required String petId,
    required String checkId,
  }) async {
    final snapshot = await _checkDocument(
      userId: userId,
      petId: petId,
      checkId: checkId,
    ).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return PawCheckFirestoreMapper.fromFirestore(
      id: EntityId(snapshot.id),
      data: data,
    );
  }

  @override
  Future<void> saveCheck(PawCheck check) async {
    final document = _checkDocument(
      userId: check.userId.value,
      petId: check.petId.value,
      checkId: check.id.value,
    );
    final snapshot = await document.get();
    final data = PawCheckFirestoreMapper.toFirestore(check)
      ..remove('createdAt')
      ..remove('updatedAt')
      ..['updatedAt'] = FirestoreMapping.serverTimestamp();

    if (!snapshot.exists) {
      data['createdAt'] = FirestoreMapping.serverTimestamp();
    }

    await document.set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteCheck({
    required String userId,
    required String petId,
    required String checkId,
  }) async {
    await _checkDocument(
      userId: userId,
      petId: petId,
      checkId: checkId,
    ).delete();
  }

  DocumentReference<Map<String, Object?>> _checkDocument({
    required String userId,
    required String petId,
    required String checkId,
  }) {
    return _firestore.doc(
      '${FirestorePaths.pawChecks(userId: userId, petId: petId)}/$checkId',
    );
  }
}
