import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/documents/domain/entities/document_attachment.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';

PetDocument _document({
  List<DocumentAttachment> attachments = const [],
  Uri? fileUrl,
  String? storagePath,
}) {
  return PetDocument(
    id: const EntityId('doc-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    title: 'Rabies certificate',
    type: PetDocumentType.vaccinationCertificate,
    attachments: attachments,
    fileUrl: fileUrl,
    storagePath: storagePath,
  );
}

DocumentAttachment _attachment(String name) {
  return DocumentAttachment(
    fileUrl: Uri.parse('https://example.com/$name'),
    storagePath: 'users/user-1/pets/pet-1/documents/doc-1/$name',
  );
}

void main() {
  group('PetDocument.files', () {
    test('returns every attachment', () {
      // The reported bug: a document scanned from two pages showed one.
      final document = _document(
        attachments: [
          _attachment('attachment_0.png'),
          _attachment('attachment_1.jpg'),
        ],
      );

      expect(document.files, hasLength(2));
      expect(document.hasFile, isTrue);
    });

    test('falls back to the legacy single-file fields', () {
      // Documents saved before multi-attachment support keep their only file
      // in fileUrl/storagePath and must keep working.
      final document = _document(
        fileUrl: Uri.parse('https://example.com/original.pdf'),
        storagePath: 'users/user-1/pets/pet-1/documents/doc-1/original.pdf',
      );

      expect(document.files, hasLength(1));
      expect(document.files.single.fileExtension, 'pdf');
      expect(document.hasFile, isTrue);
    });

    test('prefers attachments over the legacy fields when both exist', () {
      // New saves populate both shapes so an older build still shows a file.
      // The current build must not then show the first file twice.
      final document = _document(
        attachments: [
          _attachment('attachment_0.png'),
          _attachment('attachment_1.jpg'),
        ],
        fileUrl: Uri.parse('https://example.com/attachment_0.png'),
        storagePath: 'users/user-1/pets/pet-1/documents/doc-1/attachment_0.png',
      );

      expect(document.files, hasLength(2));
    });

    test('is empty with no file at all', () {
      final document = _document();

      expect(document.files, isEmpty);
      expect(document.hasFile, isFalse);
      expect(document.storagePaths, isEmpty);
    });

    test('storagePaths covers every file, so delete can clean them all up', () {
      final document = _document(
        attachments: [
          _attachment('attachment_0.png'),
          _attachment('attachment_1.jpg'),
        ],
      );

      expect(document.storagePaths, hasLength(2));
      expect(
        document.storagePaths,
        everyElement(contains('documents/doc-1/')),
      );
    });

    test('imageFiles keeps only previewable files', () {
      final document = _document(
        attachments: [
          _attachment('attachment_0.png'),
          _attachment('attachment_1.pdf'),
          _attachment('attachment_2.heic'),
        ],
      );

      expect(document.imageFiles, hasLength(2));
      expect(
        document.imageFiles.map((f) => f.fileExtension),
        ['png', 'heic'],
      );
    });
  });

  group('DocumentAttachment', () {
    test('derives the extension from the storage path', () {
      expect(_attachment('attachment_0.JPG').fileExtension, 'jpg');
      expect(_attachment('attachment_0').fileExtension, '');
      expect(_attachment('attachment_0.').fileExtension, '');
    });

    test('recognises previewable image types', () {
      for (final ext in ['jpg', 'jpeg', 'png', 'heic', 'webp']) {
        expect(_attachment('a.$ext').isImage, isTrue, reason: ext);
      }
      expect(_attachment('a.pdf').isImage, isFalse);
    });
  });
}
