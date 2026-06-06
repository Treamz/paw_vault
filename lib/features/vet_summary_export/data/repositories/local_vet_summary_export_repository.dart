import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_export.dart';
import 'package:paw_vault/features/vet_summary_export/domain/repositories/vet_summary_export_repository.dart';

class LocalVetSummaryExportRepository implements VetSummaryExportRepository {
  @override
  Future<void> deleteExport({
    required EntityId userId,
    required EntityId petId,
    required EntityId exportId,
  }) async {}

  @override
  Future<VetSummaryExport?> getExport({
    required EntityId userId,
    required EntityId petId,
    required EntityId exportId,
  }) async {
    return null;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveExport(VetSummaryExport summaryExport) async {}

  @override
  Stream<List<VetSummaryExport>> watchExports({
    required EntityId userId,
    required EntityId petId,
  }) {
    return Stream<List<VetSummaryExport>>.value(const []);
  }
}
