import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_photo.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_scan_draft.dart';

/// Analyses paw photographs into a review-only draft.
///
/// The result is never persisted by this repository and never written to
/// Firestore: it is a draft the owner must confirm, like every other AI output
/// in the app.
abstract interface class PawScanAiRepository {
  /// Describes what is visible in [photos].
  ///
  /// [location] is the owner's own answer about which paw this is — it is
  /// passed as context, not inferred as fact. [speciesLabel] lets the model
  /// account for the difference between, say, a cat's and a dog's paw.
  Future<PawScanDraft> analyzePaw({
    required List<PawPhoto> photos,
    required PawLocation location,
    String? speciesLabel,
  });
}
