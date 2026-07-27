import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';

void main() {
  group('PetDocument file helpers', () {
    PetDocument document(String storagePath) => PetDocument(
          id: const EntityId('doc-1'),
          userId: const EntityId('user-1'),
          petId: const EntityId('pet-1'),
          title: 'Passport',
          type: PetDocumentType.passport,
          fileUrl: Uri.parse('https://example.com/file'),
          storagePath: storagePath,
        );

    test('derives the file extension from the storage path', () {
      expect(document('a/b/original.pdf').fileExtension, 'pdf');
      expect(document('a/b/original.JPG').fileExtension, 'jpg');
      expect(document('a/b/original').fileExtension, '');
      expect(document('a/b/original.').fileExtension, '');
    });

    test('detects image files by extension', () {
      expect(document('a/original.jpg').hasImageFile, isTrue);
      expect(document('a/original.jpeg').hasImageFile, isTrue);
      expect(document('a/original.png').hasImageFile, isTrue);
      expect(document('a/original.heic').hasImageFile, isTrue);
      expect(document('a/original.webp').hasImageFile, isTrue);
      expect(document('a/original.pdf').hasImageFile, isFalse);
      expect(document('a/original').hasImageFile, isFalse);
    });
  });
}
