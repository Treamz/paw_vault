import 'dart:typed_data';

import 'package:paw_vault/core/storage/data/datasources/firebase_storage_data_source.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';

class FirebaseReadyStorageRepository implements StorageRepository {
  const FirebaseReadyStorageRepository(this._dataSource);

  final FirebaseStorageDataSource _dataSource;

  @override
  Future<void> delete(String path) => _dataSource.delete(path);

  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) {
    return _dataSource.uploadBytes(
      path: path,
      bytes: bytes,
      contentType: contentType,
    );
  }
}
