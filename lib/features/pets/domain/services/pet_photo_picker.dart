import 'dart:typed_data';

/// Where the user is picking a pet profile photo from.
enum PetPhotoSource {
  camera,
  gallery,
}

/// A photo selected by the user, ready to be uploaded to storage.
class PickedPetPhoto {
  const PickedPetPhoto({
    required this.bytes,
    required this.contentType,
  });

  final Uint8List bytes;

  /// MIME type used as the storage upload content type.
  final String contentType;
}

/// Port for selecting a pet profile photo from the camera or the photo
/// gallery. Returns `null` if the user cancels.
///
/// Concrete implementations live in the data layer and wrap a platform
/// image picker; the presentation layer depends only on this abstraction.
abstract interface class PetPhotoPicker {
  Future<PickedPetPhoto?> pick(PetPhotoSource source);
}
