import 'dart:typed_data';

/// A file selected by the user, ready to be uploaded to storage.
class PickedFile {
  const PickedFile({
    required this.bytes,
    required this.fileName,
    required this.extension,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;

  /// File extension without a leading dot (e.g. `pdf`, `jpg`).
  final String extension;

  /// MIME type used as the storage upload content type.
  final String contentType;
}

/// Port for selecting a document file from the device.
///
/// Concrete implementations live in the data layer and wrap a platform file
/// picker; the application layer depends only on this abstraction.
abstract interface class FilePicker {
  /// Prompts the user to pick a document, or returns `null` if cancelled.
  Future<PickedFile?> pickDocument();
}
