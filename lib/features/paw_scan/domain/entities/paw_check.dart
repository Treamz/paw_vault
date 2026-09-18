import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';

/// A paw check may only exist in the archive once the owner has confirmed it.
/// The Firebase repository rejects anything else, mirroring smart messages.
enum PawCheckStatus { confirmed }

/// A confirmed, dated paw check in a pet's journal.
class PawCheck {
  const PawCheck({
    required this.id,
    required this.userId,
    required this.petId,
    required this.location,
    required this.attentionLevel,
    required this.checkedAt,
    this.photoUrls = const [],
    this.photoStoragePaths = const [],
    this.observations = const [],
    this.summary,
    this.ownerNote,
    this.includeInVetSummary = true,
    this.confidence = 0,
    this.status = PawCheckStatus.confirmed,
    this.createdAt,
    this.updatedAt,
  });

  final EntityId id;
  final EntityId userId;
  final EntityId petId;
  final PawLocation location;
  final PawAttentionLevel attentionLevel;

  /// When the photo was taken and reviewed, as opposed to when the record was
  /// written.
  final UtcDateTime checkedAt;

  final List<Uri> photoUrls;
  final List<String> photoStoragePaths;

  /// Observations flattened to display strings at confirmation time, so the
  /// journal shows exactly what the owner saw and approved.
  final List<String> observations;

  final String? summary;

  /// The owner's own words about this check.
  final String? ownerNote;

  /// Whether this check is included in the exported vet summary PDF.
  final bool includeInVetSummary;

  final double confidence;
  final PawCheckStatus status;
  final UtcDateTime? createdAt;
  final UtcDateTime? updatedAt;

  PawCheck copyWith({
    PawLocation? location,
    PawAttentionLevel? attentionLevel,
    UtcDateTime? checkedAt,
    List<Uri>? photoUrls,
    List<String>? photoStoragePaths,
    List<String>? observations,
    String? summary,
    String? ownerNote,
    bool? includeInVetSummary,
    double? confidence,
    UtcDateTime? createdAt,
    UtcDateTime? updatedAt,
  }) {
    return PawCheck(
      id: id,
      userId: userId,
      petId: petId,
      location: location ?? this.location,
      attentionLevel: attentionLevel ?? this.attentionLevel,
      checkedAt: checkedAt ?? this.checkedAt,
      photoUrls: photoUrls ?? this.photoUrls,
      photoStoragePaths: photoStoragePaths ?? this.photoStoragePaths,
      observations: observations ?? this.observations,
      summary: summary ?? this.summary,
      ownerNote: ownerNote ?? this.ownerNote,
      includeInVetSummary: includeInVetSummary ?? this.includeInVetSummary,
      confidence: confidence ?? this.confidence,
      status: status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
