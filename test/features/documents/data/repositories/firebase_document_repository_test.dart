import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/data/datasources/firestore_document_data_source.dart';
import 'package:paw_vault/features/documents/data/repositories/firebase_document_repository.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';

void main() {
  group('FirebaseDocumentRepository', () {
    test('watches documents through the Firestore data source', () async {
      final document = _document();
      final dataSource = _FakeFirestoreDocumentDataSource(
        watchedDocuments: [
          document,
        ],
      );
      final repository = FirebaseDocumentRepository(dataSource);

      final documents = await repository
          .watchDocuments(
            userId: const EntityId('user-1'),
            petId: const EntityId('pet-1'),
          )
          .first;

      expect(documents, [document]);
      expect(dataSource.watchedUserId, 'user-1');
      expect(dataSource.watchedPetId, 'pet-1');
    });

    test('gets a document through the Firestore data source', () async {
      final document = _document();
      final dataSource = _FakeFirestoreDocumentDataSource(
        foundDocument: document,
      );
      final repository = FirebaseDocumentRepository(dataSource);

      final result = await repository.getDocument(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        documentId: const EntityId('document-1'),
      );

      expect(result, document);
      expect(dataSource.getUserId, 'user-1');
      expect(dataSource.getPetId, 'pet-1');
      expect(dataSource.getDocumentId, 'document-1');
    });

    test('saves a document through the Firestore data source', () async {
      final document = _document();
      final dataSource = _FakeFirestoreDocumentDataSource();
      final repository = FirebaseDocumentRepository(dataSource);

      await repository.saveDocument(document);

      expect(dataSource.savedDocument, document);
    });

    test('deletes a document through the Firestore data source', () async {
      final dataSource = _FakeFirestoreDocumentDataSource();
      final repository = FirebaseDocumentRepository(dataSource);

      await repository.deleteDocument(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        documentId: const EntityId('document-1'),
      );

      expect(dataSource.deletedUserId, 'user-1');
      expect(dataSource.deletedPetId, 'pet-1');
      expect(dataSource.deletedDocumentId, 'document-1');
    });
  });
}

PetDocument _document() {
  return PetDocument(
    id: const EntityId('document-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    title: 'Rabies certificate',
    type: PetDocumentType.vaccinationCertificate,
    fileUrl: Uri.parse('https://example.com/rabies.pdf'),
    storagePath: 'users/user-1/pets/pet-1/documents/document-1/original.pdf',
  );
}

class _FakeFirestoreDocumentDataSource implements FirestoreDocumentDataSource {
  _FakeFirestoreDocumentDataSource({
    this.watchedDocuments = const [],
    this.foundDocument,
  });

  final List<PetDocument> watchedDocuments;
  final PetDocument? foundDocument;

  String? watchedUserId;
  String? watchedPetId;
  String? getUserId;
  String? getPetId;
  String? getDocumentId;
  PetDocument? savedDocument;
  String? deletedUserId;
  String? deletedPetId;
  String? deletedDocumentId;

  @override
  Future<void> deleteDocument({
    required String userId,
    required String petId,
    required String documentId,
  }) async {
    deletedUserId = userId;
    deletedPetId = petId;
    deletedDocumentId = documentId;
  }

  @override
  Future<PetDocument?> getDocument({
    required String userId,
    required String petId,
    required String documentId,
  }) async {
    getUserId = userId;
    getPetId = petId;
    getDocumentId = documentId;
    return foundDocument;
  }

  @override
  Future<void> saveDocument(PetDocument document) async {
    savedDocument = document;
  }

  @override
  Stream<List<PetDocument>> watchDocuments({
    required String userId,
    required String petId,
  }) {
    watchedUserId = userId;
    watchedPetId = petId;
    return Stream<List<PetDocument>>.value(watchedDocuments);
  }
}
