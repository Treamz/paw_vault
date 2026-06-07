import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/vet_summary_export/data/datasources/firestore_vet_summary_export_data_source.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_export.dart';
import 'package:paw_vault/features/vet_summary_export/domain/repositories/vet_summary_export_repository.dart';

class FirebaseVetSummaryExportRepository implements VetSummaryExportRepository {
  const FirebaseVetSummaryExportRepository(this._dataSource);

  final FirestoreVetSummaryExportDataSource _dataSource;

  @override
  Future<void> deleteExport({
    required EntityId userId,
    required EntityId petId,
    required EntityId exportId,
  }) {
    return _dataSource.deleteExport(
      userId: userId.value,
      petId: petId.value,
      exportId: exportId.value,
    );
  }

  @override
  Future<VetSummaryExport?> getExport({
    required EntityId userId,
    required EntityId petId,
    required EntityId exportId,
  }) {
    return _dataSource.getExport(
      userId: userId.value,
      petId: petId.value,
      exportId: exportId.value,
    );
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveExport(VetSummaryExport summaryExport) {
    return _dataSource.saveExport(summaryExport);
  }

  @override
  Stream<List<VetSummaryExport>> watchExports({
    required EntityId userId,
    required EntityId petId,
  }) {
    return _dataSource.watchExports(
      userId: userId.value,
      petId: petId.value,
    );
  }
}
