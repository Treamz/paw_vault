import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_photo.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_scan_draft.dart';
import 'package:paw_vault/features/paw_scan/domain/repositories/paw_scan_ai_repository.dart';

/// Stand-in for when there is no model behind the app.
///
/// Reports the photo as unreadable rather than returning an attention level:
/// a fabricated health signal would be worse than no feature at all.
class NoopPawScanAiRepository implements PawScanAiRepository {
  const NoopPawScanAiRepository();

  @override
  Future<PawScanDraft> analyzePaw({
    required List<PawPhoto> photos,
    required PawLocation location,
    String? speciesLabel,
  }) async {
    return const PawScanDraft.unusable(
      photoQuality: PawScanPhotoQuality.usable,
    );
  }
}
