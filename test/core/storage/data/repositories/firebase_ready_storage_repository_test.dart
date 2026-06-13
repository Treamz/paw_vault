import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/storage/data/datasources/firebase_storage_data_source.dart';
import 'package:paw_vault/core/storage/data/repositories/firebase_ready_storage_repository.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';

void main() {
  group('FirebaseReadyStorageRepository', () {
    test('uploads bytes through the data source', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final dataSource = _FakeFirebaseStorageDataSource(
        uploadedFile: StorageFile(
          path: 'users/user-1/pets/pet-1/photos/profile.jpg',
          downloadUrl: Uri.parse('https://example.com/profile.jpg'),
        ),
      );
      final repository = FirebaseReadyStorageRepository(dataSource);

      final result = await repository.uploadBytes(
        path: 'users/user-1/pets/pet-1/photos/profile.jpg',
        bytes: bytes,
        contentType: 'image/jpeg',
      );

      expect(result.path, 'users/user-1/pets/pet-1/photos/profile.jpg');
      expect(result.downloadUrl, Uri.parse('https://example.com/profile.jpg'));
      expect(
        dataSource.uploadedPath,
        'users/user-1/pets/pet-1/photos/profile.jpg',
      );
      expect(dataSource.uploadedBytes, bytes);
      expect(dataSource.uploadedContentType, 'image/jpeg');
    });

    test('deletes by path through the data source', () async {
      final dataSource = _FakeFirebaseStorageDataSource();
      final repository = FirebaseReadyStorageRepository(dataSource);

      await repository
          .delete('users/user-1/pets/pet-1/documents/doc-1/original.pdf');

      expect(
        dataSource.deletedPath,
        'users/user-1/pets/pet-1/documents/doc-1/original.pdf',
      );
    });
  });
}

class _FakeFirebaseStorageDataSource implements FirebaseStorageDataSource {
  _FakeFirebaseStorageDataSource({
    StorageFile? uploadedFile,
  }) : uploadedFile = uploadedFile ??
            StorageFile(
              path: 'path',
              downloadUrl: Uri.parse('https://example.com/file'),
            );

  final StorageFile uploadedFile;

  String? uploadedPath;
  Uint8List? uploadedBytes;
  String? uploadedContentType;
  String? deletedPath;

  @override
  Future<void> delete(String path) async {
    deletedPath = path;
  }

  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadedPath = path;
    uploadedBytes = bytes;
    uploadedContentType = contentType;
    return uploadedFile;
  }
}
