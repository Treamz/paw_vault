import 'dart:typed_data';

import 'package:paw_vault/core/storage/data/datasources/firebase_storage_data_source.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';

class NoopFirebaseStorageDataSource implements FirebaseStorageDataSource {
  @override
  Future<void> delete(String path) async {}

  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    return StorageFile(
      path: path,
      downloadUrl: Uri(path: path),
    );
  }
}
