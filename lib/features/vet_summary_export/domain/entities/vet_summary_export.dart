import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';

class VetSummaryExport {
  const VetSummaryExport({
    required this.id,
    required this.userId,
    required this.petId,
    required this.createdAt,
    this.fileUrl,
    this.storagePath,
    this.fileName,
  });

  final EntityId id;
  final EntityId userId;
  final EntityId petId;
  final UtcDateTime createdAt;
  final Uri? fileUrl;
  final String? storagePath;

  /// The name the owner gave this export when saving it.
  ///
  /// Null for exports saved before the name was kept, which is why
  /// [displayName] exists — never render this directly.
  final String? fileName;

  /// What to call this export in the UI, or null when it has no name — an
  /// export saved before the name was kept. Callers fall back to its date.
  ///
  /// The storage object is deliberately *not* used as a fallback: it is named
  /// after the export id, so it would surface a raw microsecond timestamp.
  String? get displayName {
    final name = fileName?.trim();
    return name == null || name.isEmpty ? null : name;
  }
}
