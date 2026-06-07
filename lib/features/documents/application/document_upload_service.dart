import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/storage/firebase_storage_paths.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';

/// Picks a document file and uploads its bytes to storage, returning the
/// resulting storage path and download URL for persistence as metadata.
class DocumentUploadService {
  DocumentUploadService({
    required FilePicker filePicker,
    required StorageRepository storageRepository,
  })  : _filePicker = filePicker,
        _storageRepository = storageRepository;

  final FilePicker _filePicker;
  final StorageRepository _storageRepository;

  /// Prompts the user to pick a document and uploads it under the given
  /// [documentId]. Returns the uploaded [StorageFile], or `null` if the user
  /// cancelled the picker.
  Future<StorageFile?> pickAndUploadDocument({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
  }) async {
    final picked = await _filePicker.pickDocument();
    if (picked == null) {
      return null;
    }

    final path = FirebaseStoragePaths.documentOriginal(
      userId: userId.value,
      petId: petId.value,
      documentId: documentId.value,
      extension: picked.extension,
    );

    return _storageRepository.uploadBytes(
      path: path,
      bytes: picked.bytes,
      contentType: picked.contentType,
    );
  }
}
