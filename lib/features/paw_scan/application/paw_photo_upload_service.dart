import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/storage/firebase_storage_paths.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';

/// Uploads the photos of a confirmed paw check.
///
/// Only called after the owner confirms: an uploaded object is stored data, so
/// uploading during review would save something the owner never approved, and
/// a discarded scan would leave orphaned bytes behind.
class PawPhotoUploadService {
  PawPhotoUploadService({required StorageRepository storageRepository})
      : _storageRepository = storageRepository;

  final StorageRepository _storageRepository;

  Future<List<StorageFile>> uploadPawPhotos({
    required EntityId userId,
    required EntityId petId,
    required EntityId checkId,
    required List<PickedFile> files,
  }) async {
    final uploaded = <StorageFile>[];

    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      uploaded.add(
        await _storageRepository.uploadBytes(
          path: FirebaseStoragePaths.pawCheckPhoto(
            userId: userId.value,
            petId: petId.value,
            checkId: checkId.value,
            photoId: '$index',
          ),
          bytes: file.bytes,
          contentType: file.contentType,
        ),
      );
    }

    return uploaded;
  }

  /// Removes already-uploaded photos after a failed save, so a check that
  /// never made it into Firestore does not leave bytes behind.
  Future<void> deletePawPhotos(Iterable<String> storagePaths) async {
    for (final path in storagePaths) {
      try {
        await _storageRepository.delete(path);
      } catch (_) {
        // Best effort: a failed rollback must not mask the original error.
      }
    }
  }
}
