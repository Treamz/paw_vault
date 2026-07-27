import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/storage/firebase_storage_paths.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/timeline/domain/services/event_photo_picker.dart';

/// Uploads picked event attachment photos to storage, returning the resulting
/// storage path and download URL for persistence on the event.
class EventAttachmentUploadService {
  EventAttachmentUploadService({required StorageRepository storageRepository})
      : _storageRepository = storageRepository;

  final StorageRepository _storageRepository;

  Future<StorageFile> uploadAttachment({
    required EntityId userId,
    required EntityId petId,
    required EntityId eventId,
    required String attachmentId,
    required PickedEventPhoto photo,
  }) {
    final path = FirebaseStoragePaths.eventAttachment(
      userId: userId.value,
      petId: petId.value,
      eventId: eventId.value,
      attachmentId: attachmentId,
      extension: photo.extension,
    );

    return _storageRepository.uploadBytes(
      path: path,
      bytes: photo.bytes,
      contentType: photo.contentType,
    );
  }
}
