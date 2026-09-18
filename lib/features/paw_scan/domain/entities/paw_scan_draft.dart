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

  /// The model's own safety filters blocked the request or the reply. Most
  /// likely on a badly injured paw — the case where the owner most needs to be
  /// told to call a vet, so it gets its own state and its own message.
  blocked,

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
        confidence = null,
        status = PawScanDraftStatus.unusablePhoto,
        safetyFilterApplied = false;

  /// The model refused to answer. Carries no attention level: the UI tells the
  /// owner to contact their vet directly.
  const PawScanDraft.blocked()
      : requiresConfirmation = true,
        location = PawLocation.unspecified,
        observations = const [],
        attentionLevel = PawAttentionLevel.undetermined,
        summary = null,
        photoQuality = PawScanPhotoQuality.usable,
        confidence = null,
        status = PawScanDraftStatus.blocked,
        safetyFilterApplied = false;

  /// Always `true` — a scan result must be reviewed before anything is saved.
  final bool requiresConfirmation;

  final PawLocation location;
  final List<PawObservation> observations;
  final PawAttentionLevel attentionLevel;

  /// One neutral sentence about what is visible. Never a conclusion.
  final String? summary;

  final PawScanPhotoQuality photoQuality;
  final double? confidence;
  final PawScanDraftStatus status;

  /// `true` when `PawScanSafetyFilter` rewrote model output.
  final bool safetyFilterApplied;

  static const lowConfidenceThreshold = 0.6;

  bool get isLowConfidence =>
      confidence != null && confidence! < lowConfidenceThreshold;

  /// Whether an attention level and observations can be shown at all. When
  /// `false` the UI asks for a retake, or tells the owner to call their vet,
  /// and shows no attention level.
  bool get isUsable =>
      status != PawScanDraftStatus.unusablePhoto &&
      status != PawScanDraftStatus.blocked;

  /// Whether this draft may be written to the journal. Only a reviewed result
  /// qualifies — a rejected scan can never be logged.
  bool get canBeLogged =>
      status == PawScanDraftStatus.awaitingReview ||
      status == PawScanDraftStatus.lowConfidenceReview;

  bool get hasObservations => observations.isNotEmpty;

  PawScanDraft copyWith({
    bool? requiresConfirmation,
    PawLocation? location,
    List<PawObservation>? observations,
    PawAttentionLevel? attentionLevel,
    String? summary,
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
      photoQuality: photoQuality ?? this.photoQuality,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      safetyFilterApplied: safetyFilterApplied ?? this.safetyFilterApplied,
    );
  }
}
