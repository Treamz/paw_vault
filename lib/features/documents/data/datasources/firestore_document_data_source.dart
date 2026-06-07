import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';

abstract interface class FirestoreDocumentDataSource {
  Stream<List<PetDocument>> watchDocuments({
    required String userId,
    required String petId,
  });

  Future<PetDocument?> getDocument({
    required String userId,
    required String petId,
    required String documentId,
  });

  Future<void> saveDocument(PetDocument document);

  Future<void> deleteDocument({
    required String userId,
    required String petId,
    required String documentId,
  });
}
