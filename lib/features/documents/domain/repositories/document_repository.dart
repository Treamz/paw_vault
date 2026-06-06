import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';

abstract interface class DocumentRepository {
  Future<void> initialize();

  Stream<List<PetDocument>> watchDocuments({
    required EntityId userId,
    required EntityId petId,
  });

  Future<PetDocument?> getDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  });

  Future<void> saveDocument(PetDocument document);

  Future<void> deleteDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  });
}
