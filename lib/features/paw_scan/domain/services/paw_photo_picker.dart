import 'package:paw_vault/features/documents/domain/services/file_picker.dart';

enum PawPhotoSource { camera, gallery }

/// Port for capturing a paw photo.
///
/// Implementations live in the data layer and are expected to downscale the
/// image before returning it: paw photos are only ever used for on-screen
/// review, one AI request, and a thumbnail in History.
abstract interface class PawPhotoPicker {
  /// Prompts for a photo, or returns `null` if the owner cancelled.
  Future<PickedFile?> pick(PawPhotoSource source);

  /// Prompts for several photos from the gallery at once, newest selection
  /// first; empty if the owner cancelled.
  ///
  /// Only the gallery can offer this — the camera takes one photo at a time,
  /// so that path keeps using [pick].
  Future<List<PickedFile>> pickMultipleFromGallery();
}
