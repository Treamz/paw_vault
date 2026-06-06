import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_paths.dart';
import 'package:paw_vault/features/documents/data/datasources/firestore_document_data_source.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';

class FlutterFireDocumentDataSource implements FirestoreDocumentDataSource {
  FlutterFireDocumentDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<PetDocument>> watchDocuments({
    required String userId,
    required String petId,
  }) {
    return _firestore
        .collection(FirestorePaths.documents(userId: userId, petId: petId))
        .snapshots()
        .map((_) => const <PetDocument>[]);
  }
}
