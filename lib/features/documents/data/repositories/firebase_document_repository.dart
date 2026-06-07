import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/data/datasources/firestore_document_data_source.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';
import 'package:paw_vault/features/documents/domain/repositories/document_repository.dart';

class FirebaseDocumentRepository implements DocumentRepository {
  const FirebaseDocumentRepository(this._dataSource);

  final FirestoreDocumentDataSource _dataSource;

  @override
  Future<void> deleteDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) {
    return _dataSource.deleteDocument(
      userId: userId.value,
      petId: petId.value,
      documentId: documentId.value,
    );
  }

  @override
  Future<PetDocument?> getDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) {
    return _dataSource.getDocument(
      userId: userId.value,
      petId: petId.value,
      documentId: documentId.value,
    );
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveDocument(PetDocument document) {
    return _dataSource.saveDocument(document);
  }

  @override
  Stream<List<PetDocument>> watchDocuments({
    required EntityId userId,
    required EntityId petId,
  }) {
    return _dataSource.watchDocuments(
      userId: userId.value,
      petId: petId.value,
    );
  }
}
