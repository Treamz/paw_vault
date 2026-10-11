import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/storage/firebase_storage_paths.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/documents/domain/entities/document_attachment.dart';
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

    return uploadDocumentFile(
      userId: userId,
      petId: petId,
      documentId: documentId,
      file: picked,
    );
  }

  /// Uploads an already-picked [file] under the document storage path. Used
  /// when the file was selected elsewhere (e.g. the extraction flow).
  Future<StorageFile> uploadDocumentFile({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
    required PickedFile file,
  }) {
    final path = FirebaseStoragePaths.documentOriginal(
      userId: userId.value,
      petId: petId.value,
      documentId: documentId.value,
      extension: file.extension,
    );

    return _storageRepository.uploadBytes(
      path: path,
      bytes: file.bytes,
      contentType: file.contentType,
    );
  }

  /// Uploads every picked [files] as a separate attachment of [documentId].
  ///
  /// Each file gets its own object, so attaching several to one document no
  /// longer overwrites or discards any of them.
  Future<List<DocumentAttachment>> uploadDocumentFiles({
    required EntityId userId,
    required EntityId petId,
    required EntityId documentId,
    required List<PickedFile> files,
  }) async {
    final uploaded = <DocumentAttachment>[];

    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final stored = await _storageRepository.uploadBytes(
        path: FirebaseStoragePaths.documentAttachment(
          userId: userId.value,
          petId: petId.value,
          documentId: documentId.value,
          index: index,
          extension: file.extension,
        ),
        bytes: file.bytes,
        contentType: file.contentType,
      );
      uploaded.add(
        DocumentAttachment(
          fileUrl: stored.downloadUrl,
          storagePath: stored.path,
        ),
      );
    }

    return uploaded;
  }

  /// Removes stored attachment objects, so deleting a document does not leave
  /// its extra files orphaned in Storage.
  Future<void> deleteDocumentFiles(Iterable<String> storagePaths) async {
    for (final path in storagePaths) {
      try {
        await _storageRepository.delete(path);
      } catch (_) {
        // Best effort: one failed delete must not abort the rest.
      }
    }
  }
}
