import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/storage/firebase_storage_paths.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/pets/domain/services/pet_photo_picker.dart';

/// Uploads a picked pet profile photo to storage, returning the resulting
/// storage path and download URL for persistence on the pet.
class PetPhotoUploadService {
  PetPhotoUploadService({required StorageRepository storageRepository})
      : _storageRepository = storageRepository;

  final StorageRepository _storageRepository;

  Future<StorageFile> uploadProfilePhoto({
    required EntityId userId,
    required EntityId petId,
    required PickedPetPhoto photo,
  }) {
    final path = FirebaseStoragePaths.profilePhoto(
      userId: userId.value,
      petId: petId.value,
    );

    return _storageRepository.uploadBytes(
      path: path,
      bytes: photo.bytes,
      contentType: photo.contentType,
    );
  }
}
