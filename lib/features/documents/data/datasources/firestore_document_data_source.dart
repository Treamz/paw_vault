import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';

abstract interface class FirestoreDocumentDataSource {
  Stream<List<PetDocument>> watchDocuments({
    required String userId,
    required String petId,
  });
}
