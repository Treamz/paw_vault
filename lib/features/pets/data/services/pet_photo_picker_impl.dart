import 'package:image_picker/image_picker.dart';
import 'package:paw_vault/features/pets/domain/services/pet_photo_picker.dart';

/// [PetPhotoPicker] backed by `image_picker` (camera/gallery).
class PetPhotoPickerImpl implements PetPhotoPicker {
  PetPhotoPickerImpl({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  /// Profile photos are shown as small avatars, so downscale and recompress
  /// on pick to keep uploads fast.
  static const _maxDimension = 1280.0;
  static const _imageQuality = 85;

  @override
  Future<PickedPetPhoto?> pick(PetPhotoSource source) async {
    final image = await _imagePicker.pickImage(
      source: switch (source) {
        PetPhotoSource.camera => ImageSource.camera,
        PetPhotoSource.gallery => ImageSource.gallery,
      },
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: _imageQuality,
    );
    if (image == null) {
      return null;
    }

    final bytes = await image.readAsBytes();

    return PickedPetPhoto(
      bytes: bytes,
      contentType: _contentTypeFor(image.name),
    );
  }

  String _contentTypeFor(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final extension =
        dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'heic' => 'image/heic',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
