import 'package:image_picker/image_picker.dart' hide PickedFile;
import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/paw_scan/domain/services/paw_photo_picker.dart';

/// [PawPhotoPicker] backed by `image_picker`.
///
/// Unlike the document picker this one downscales and re-encodes: a paw photo
/// is only ever reviewed on screen, sent once to the model, and shown as a
/// history thumbnail, so a full-resolution capture would cost a slower AI
/// request, more storage, and more egress for no visible benefit.
class PawPhotoPickerImpl implements PawPhotoPicker {
  PawPhotoPickerImpl({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  static const maxDimension = 1600.0;
  static const jpegQuality = 85;

  @override
  Future<PickedFile?> pick(PawPhotoSource source) async {
    final image = await _imagePicker.pickImage(
      source: switch (source) {
        PawPhotoSource.camera => ImageSource.camera,
        PawPhotoSource.gallery => ImageSource.gallery,
      },
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      imageQuality: jpegQuality,
    );

    if (image == null) {
      return null;
    }

    return _toPickedFile(image);
  }

  @override
  Future<List<PickedFile>> pickMultipleFromGallery() async {
    final images = await _imagePicker.pickMultiImage(
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      imageQuality: jpegQuality,
    );

    // Read sequentially: decoding several downscaled photos at once is a
    // large, pointless memory spike on a phone.
    final picked = <PickedFile>[];
    for (final image in images) {
      picked.add(await _toPickedFile(image));
    }
    return picked;
  }

  Future<PickedFile> _toPickedFile(XFile image) async {
    final bytes = await image.readAsBytes();

    // `imageQuality` forces a re-encode to JPEG, but the returned name can
    // still carry the original extension (HEIC on iOS). Declare what the bytes
    // actually are rather than trusting the file name.
    return PickedFile(
      bytes: bytes,
      fileName: image.name,
      extension: 'jpg',
      contentType: 'image/jpeg',
    );
  }
}
