import 'package:paw_vault/features/documents/domain/services/file_picker.dart';

/// Where the user is picking a document file from.
enum DocumentSource {
  camera,
  gallery,
  file,
}

/// Port for selecting a document to extract, from the camera, the photo
/// gallery, or a file (PDF/image). Returns `null` if the user cancels.
abstract interface class DocumentSourcePicker {
  Future<PickedFile?> pick(DocumentSource source);

  /// Selects several gallery photos at once; empty if the owner cancelled.
  ///
  /// The camera takes one photo at a time, so that path keeps using [pick].
  Future<List<PickedFile>> pickMultipleFromGallery();
}
