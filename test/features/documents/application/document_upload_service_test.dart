import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/documents/application/document_upload_service.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';

void main() {
  group('DocumentUploadService', () {
    test('uploads the picked file under the document storage path', () async {
      final picked = PickedFile(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'passport.pdf',
        extension: 'pdf',
        contentType: 'application/pdf',
      );
      final filePicker = _FakeFilePicker(picked: picked);
      final storageRepository = _FakeStorageRepository();
      final service = DocumentUploadService(
        filePicker: filePicker,
        storageRepository: storageRepository,
      );

      final result = await service.pickAndUploadDocument(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        documentId: const EntityId('doc-1'),
      );

      expect(
        storageRepository.uploadedPath,
        'users/user-1/pets/pet-1/documents/doc-1/original.pdf',
      );
      expect(storageRepository.uploadedBytes, picked.bytes);
      expect(storageRepository.uploadedContentType, 'application/pdf');
      expect(result, isNotNull);
      expect(
        result!.path,
        'users/user-1/pets/pet-1/documents/doc-1/original.pdf',
      );
    });

    test('returns null and does not upload when the picker is cancelled',
        () async {
      final filePicker = _FakeFilePicker();
      final storageRepository = _FakeStorageRepository();
      final service = DocumentUploadService(
        filePicker: filePicker,
        storageRepository: storageRepository,
      );

      final result = await service.pickAndUploadDocument(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        documentId: const EntityId('doc-1'),
      );

      expect(result, isNull);
      expect(storageRepository.uploadCallCount, isZero);
    });
  });
}

class _FakeFilePicker implements FilePicker {
  _FakeFilePicker({this.picked});

  final PickedFile? picked;

  @override
  Future<PickedFile?> pickDocument() async => picked;
}

class _FakeStorageRepository implements StorageRepository {
  int uploadCallCount = 0;
  String? uploadedPath;
  Uint8List? uploadedBytes;
  String? uploadedContentType;

  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadCallCount++;
    uploadedPath = path;
    uploadedBytes = bytes;
    uploadedContentType = contentType;
    return StorageFile(
      path: path,
      downloadUrl: Uri.parse('https://storage.example.com/$path'),
    );
  }

  @override
  Future<void> delete(String path) async {}
}
