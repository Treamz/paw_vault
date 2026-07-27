import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/storage/domain/entities/storage_file.dart';
import 'package:paw_vault/core/storage/domain/repositories/storage_repository.dart';
import 'package:paw_vault/features/pets/application/pet_photo_upload_service.dart';
import 'package:paw_vault/features/pets/domain/services/pet_photo_picker.dart';

void main() {
  group('PetPhotoUploadService', () {
    test('uploads photo bytes under the pet profile photo path', () async {
      final storageRepository = _FakeStorageRepository();
      final service = PetPhotoUploadService(
        storageRepository: storageRepository,
      );
      final photo = PickedPetPhoto(
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/jpeg',
      );

      final uploaded = await service.uploadProfilePhoto(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        photo: photo,
      );

      expect(
        storageRepository.uploadedPath,
        'users/user-1/pets/pet-1/photos/profile.jpg',
      );
      expect(storageRepository.uploadedBytes, photo.bytes);
      expect(storageRepository.uploadedContentType, 'image/jpeg');
      expect(uploaded.path, storageRepository.uploadedPath);
      expect(
        uploaded.downloadUrl,
        Uri.parse(
          'https://cdn.example.com/users/user-1/pets/pet-1/photos/profile.jpg',
        ),
      );
    });
  });
}

class _FakeStorageRepository implements StorageRepository {
  String? uploadedPath;
  Uint8List? uploadedBytes;
  String? uploadedContentType;

  @override
  Future<void> delete(String path) async {}

  @override
  Future<StorageFile> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadedPath = path;
    uploadedBytes = bytes;
    uploadedContentType = contentType;
    return StorageFile(
      path: path,
      downloadUrl: Uri.parse('https://cdn.example.com/$path'),
    );
  }
}
