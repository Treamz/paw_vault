import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_export.dart';

abstract interface class FirestoreVetSummaryExportDataSource {
  Stream<List<VetSummaryExport>> watchExports({
    required String userId,
    required String petId,
  });

  Future<VetSummaryExport?> getExport({
    required String userId,
    required String petId,
    required String exportId,
  });

  Future<void> saveExport(VetSummaryExport summaryExport);

  Future<void> deleteExport({
    required String userId,
    required String petId,
    required String exportId,
  });
}
