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
  });

  final EntityId id;
  final EntityId userId;
  final EntityId petId;
  final UtcDateTime createdAt;
  final Uri? fileUrl;
  final String? storagePath;
}
