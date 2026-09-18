import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_observation.dart';

/// Whether the submitted photo could be read at all.
enum PawScanPhotoQuality {
  usable,
  blurry,
  tooDark,
  tooFarAway,

  /// The photo does not show a pet's paw.
  notAPaw,
}

enum PawScanDraftStatus {
  awaitingReview,

  /// Low model confidence, or the safety filter rewrote something.
  lowConfidenceReview,

  /// The photo could not be used. No attention level is shown to the owner —
  /// they are asked to retake instead.
  unusablePhoto,

  confirmed,
  dismissed,
}

/// The transient result of a paw scan. Never persisted: the owner reviews it
/// and only a confirmed `PawCheck` is written.
class PawScanDraft {
  const PawScanDraft({
    this.requiresConfirmation = true,
    this.location = PawLocation.unspecified,
    this.observations = const [],
    this.attentionLevel = PawAttentionLevel.undetermined,
    this.summary,
    this.suggestedRecheckInDays,
    this.photoQuality = PawScanPhotoQuality.usable,
    this.confidence,
    this.status = PawScanDraftStatus.awaitingReview,
    this.safetyFilterApplied = false,
  });

  /// An unusable photo: the owner is asked to retake, and no attention level
  /// is surfaced. Used for non-paw images, unreadable photos, and the
  /// local-first no-op, so a health signal is never fabricated.
  const PawScanDraft.unusable({
    required this.photoQuality,
    this.location = PawLocation.unspecified,
  })  : requiresConfirmation = true,
        observations = const [],
        attentionLevel = PawAttentionLevel.undetermined,
        summary = null,
        suggestedRecheckInDays = null,
        confidence = null,
        status = PawScanDraftStatus.unusablePhoto,
        safetyFilterApplied = false;

  /// Always `true` — a scan result must be reviewed before anything is saved.
  final bool requiresConfirmation;

  final PawLocation location;
  final List<PawObservation> observations;
  final PawAttentionLevel attentionLevel;

  /// One neutral sentence about what is visible. Never a conclusion.
  final String? summary;

  /// How many days the model suggests before looking again. Drives the
  /// pre-filled follow-up reminder; the owner still saves it themselves.
  final int? suggestedRecheckInDays;

  final PawScanPhotoQuality photoQuality;
  final double? confidence;
  final PawScanDraftStatus status;

  /// `true` when `PawScanSafetyFilter` rewrote model output.
  final bool safetyFilterApplied;

  static const lowConfidenceThreshold = 0.6;

  bool get isLowConfidence =>
      confidence != null && confidence! < lowConfidenceThreshold;

  /// Whether a result can be shown at all. When `false` the UI asks for a
  /// retake and shows no attention level.
  bool get isUsable => status != PawScanDraftStatus.unusablePhoto;

  bool get hasObservations => observations.isNotEmpty;

  PawScanDraft copyWith({
    bool? requiresConfirmation,
    PawLocation? location,
    List<PawObservation>? observations,
    PawAttentionLevel? attentionLevel,
    String? summary,
    int? suggestedRecheckInDays,
    PawScanPhotoQuality? photoQuality,
    double? confidence,
    PawScanDraftStatus? status,
    bool? safetyFilterApplied,
    bool clearSummary = false,
  }) {
    return PawScanDraft(
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      location: location ?? this.location,
      observations: observations ?? this.observations,
      attentionLevel: attentionLevel ?? this.attentionLevel,
      summary: clearSummary ? null : summary ?? this.summary,
      suggestedRecheckInDays:
          suggestedRecheckInDays ?? this.suggestedRecheckInDays,
      photoQuality: photoQuality ?? this.photoQuality,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      safetyFilterApplied: safetyFilterApplied ?? this.safetyFilterApplied,
    );
  }
}
