import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_export.dart';

abstract interface class VetSummaryExportRepository {
  Future<void> initialize();

  Stream<List<VetSummaryExport>> watchExports({
    required EntityId userId,
    required EntityId petId,
  });

  Future<VetSummaryExport?> getExport({
    required EntityId userId,
    required EntityId petId,
    required EntityId exportId,
  });

  Future<void> saveExport(VetSummaryExport summaryExport);

  Future<void> deleteExport({
    required EntityId userId,
    required EntityId petId,
    required EntityId exportId,
  });
}
