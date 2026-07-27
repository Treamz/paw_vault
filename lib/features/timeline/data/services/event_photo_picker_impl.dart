import 'package:image_picker/image_picker.dart';
import 'package:paw_vault/features/timeline/domain/services/event_photo_picker.dart';

/// [EventPhotoPicker] backed by `image_picker` (camera/gallery).
class EventPhotoPickerImpl implements EventPhotoPicker {
  EventPhotoPickerImpl({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  /// Attachments are viewed on-device, so downscale and recompress on pick to
  /// keep uploads fast.
  static const _maxDimension = 1600.0;
  static const _imageQuality = 85;

  @override
  Future<PickedEventPhoto?> pick(EventPhotoSource source) async {
    final image = await _imagePicker.pickImage(
      source: switch (source) {
        EventPhotoSource.camera => ImageSource.camera,
        EventPhotoSource.gallery => ImageSource.gallery,
      },
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: _imageQuality,
    );
    if (image == null) {
      return null;
    }

    final bytes = await image.readAsBytes();
    final extension = _extensionOf(image.name);

    return PickedEventPhoto(
      bytes: bytes,
      contentType: _contentTypeFor(extension),
      extension: extension,
    );
  }

  String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) {
      return 'jpg';
    }
    return fileName.substring(dot + 1).toLowerCase();
  }

  String _contentTypeFor(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'heic' => 'image/heic',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
