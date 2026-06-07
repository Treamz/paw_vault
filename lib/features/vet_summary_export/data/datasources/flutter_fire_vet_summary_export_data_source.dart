import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';
import 'package:paw_vault/features/vet_summary_export/data/datasources/firestore_vet_summary_export_data_source.dart';
import 'package:paw_vault/features/vet_summary_export/data/mappers/vet_summary_export_firestore_mapper.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_export.dart';

class FlutterFireVetSummaryExportDataSource
    implements FirestoreVetSummaryExportDataSource {
  FlutterFireVetSummaryExportDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> deleteExport({
    required String userId,
    required String petId,
    required String exportId,
  }) async {
    await _exportDocument(
      userId: userId,
      petId: petId,
      exportId: exportId,
    ).delete();
  }

  @override
  Future<VetSummaryExport?> getExport({
    required String userId,
    required String petId,
    required String exportId,
  }) async {
    final snapshot = await _exportDocument(
      userId: userId,
      petId: petId,
      exportId: exportId,
    ).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return VetSummaryExportFirestoreMapper.fromFirestore(
      id: EntityId(snapshot.id),
      data: data,
    );
  }

  @override
  Future<void> saveExport(VetSummaryExport summaryExport) async {
    final document = _exportDocument(
      userId: summaryExport.userId.value,
      petId: summaryExport.petId.value,
      exportId: summaryExport.id.value,
    );
    final data = VetSummaryExportFirestoreMapper.toFirestore(summaryExport)
      ..remove('createdAt')
      ..['createdAt'] = FirestoreMapping.serverTimestamp();

    await document.set(data, SetOptions(merge: true));
  }

  @override
  Stream<List<VetSummaryExport>> watchExports({
    required String userId,
    required String petId,
  }) {
    return _firestore
        .collection(
          FirestorePaths.vetSummaryExports(userId: userId, petId: petId),
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => VetSummaryExportFirestoreMapper.fromFirestore(
                  id: EntityId(document.id),
                  data: document.data(),
                ),
              )
              .toList(),
        );
  }

  DocumentReference<Map<String, Object?>> _exportDocument({
    required String userId,
    required String petId,
    required String exportId,
  }) {
    return _firestore.doc(
      '${FirestorePaths.vetSummaryExports(userId: userId, petId: petId)}/$exportId',
    );
  }
}
