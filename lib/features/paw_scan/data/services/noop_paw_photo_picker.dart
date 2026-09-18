import 'package:paw_vault/features/documents/domain/services/file_picker.dart';
import 'package:paw_vault/features/paw_scan/domain/services/paw_photo_picker.dart';

/// Stand-in picker that always reports a cancelled capture. Used as the
/// default so a directly constructed [AppDependencies] needs no camera.
class NoopPawPhotoPicker implements PawPhotoPicker {
  const NoopPawPhotoPicker();

  @override
  Future<PickedFile?> pick(PawPhotoSource source) async => null;
}
