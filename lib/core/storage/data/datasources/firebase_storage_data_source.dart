import 'dart:typed_data';

import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';

abstract interface class FirebaseStorageDataSource {
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  });

  Future<void> delete(String path);
}
