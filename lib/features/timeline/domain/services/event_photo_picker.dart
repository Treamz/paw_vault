import 'dart:typed_data';

/// Where the user is picking an event attachment photo from.
enum EventPhotoSource {
  camera,
  gallery,
}

/// A photo selected by the user, ready to be uploaded as an event attachment.
class PickedEventPhoto {
  const PickedEventPhoto({
    required this.bytes,
    required this.contentType,
    required this.extension,
  });

  final Uint8List bytes;

  /// MIME type used as the storage upload content type.
  final String contentType;

  /// File extension without a leading dot (e.g. `jpg`).
  final String extension;
}

/// Port for selecting an event attachment photo from the camera or the photo
/// gallery. Returns `null` if the user cancels.
///
/// Concrete implementations live in the data layer and wrap a platform
/// image picker; the presentation layer depends only on this abstraction.
abstract interface class EventPhotoPicker {
  Future<PickedEventPhoto?> pick(EventPhotoSource source);
}
