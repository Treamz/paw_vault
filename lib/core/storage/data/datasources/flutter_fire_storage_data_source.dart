import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:paw_vault/core/storage/data/datasources/firebase_storage_data_source.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';

class FlutterFireStorageDataSource implements FirebaseStorageDataSource {
  FlutterFireStorageDataSource(this._storage);

  final FirebaseStorage _storage;

  @override
  Future<void> delete(String path) {
    return _storage.ref(path).delete();
  }

  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final ref = _storage.ref(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );

    return StorageFile(
      path: path,
      downloadUrl: Uri.parse(await ref.getDownloadURL()),
    );
  }
}
