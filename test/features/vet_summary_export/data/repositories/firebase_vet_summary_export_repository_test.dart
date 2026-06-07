import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/vet_summary_export/data/datasources/firestore_vet_summary_export_data_source.dart';
import 'package:paw_vault/features/vet_summary_export/data/repositories/firebase_vet_summary_export_repository.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_export.dart';

void main() {
  group('FirebaseVetSummaryExportRepository', () {
    test('watches exports through the Firestore data source', () async {
      final summaryExport = _summaryExport();
      final dataSource = _FakeFirestoreVetSummaryExportDataSource(
        watchedExports: [summaryExport],
      );
      final repository = FirebaseVetSummaryExportRepository(dataSource);

      final exports = await repository
          .watchExports(
            userId: const EntityId('user-1'),
            petId: const EntityId('pet-1'),
          )
          .first;

      expect(exports, [summaryExport]);
      expect(dataSource.watchedUserId, 'user-1');
      expect(dataSource.watchedPetId, 'pet-1');
    });

    test('gets an export through the Firestore data source', () async {
      final summaryExport = _summaryExport();
      final dataSource = _FakeFirestoreVetSummaryExportDataSource(
        foundExport: summaryExport,
      );
      final repository = FirebaseVetSummaryExportRepository(dataSource);

      final result = await repository.getExport(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        exportId: const EntityId('export-1'),
      );

      expect(result, summaryExport);
      expect(dataSource.getUserId, 'user-1');
      expect(dataSource.getPetId, 'pet-1');
      expect(dataSource.getExportId, 'export-1');
    });

    test('saves an export through the Firestore data source', () async {
      final summaryExport = _summaryExport();
      final dataSource = _FakeFirestoreVetSummaryExportDataSource();
      final repository = FirebaseVetSummaryExportRepository(dataSource);

      await repository.saveExport(summaryExport);

      expect(dataSource.savedExport, summaryExport);
    });

    test('deletes an export through the Firestore data source', () async {
      final dataSource = _FakeFirestoreVetSummaryExportDataSource();
      final repository = FirebaseVetSummaryExportRepository(dataSource);

      await repository.deleteExport(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        exportId: const EntityId('export-1'),
      );

      expect(dataSource.deletedUserId, 'user-1');
      expect(dataSource.deletedPetId, 'pet-1');
      expect(dataSource.deletedExportId, 'export-1');
    });
  });
}

VetSummaryExport _summaryExport() {
  return VetSummaryExport(
    id: const EntityId('export-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    createdAt: UtcDateTime(DateTime.utc(2026, 1, 2, 3, 4)),
    fileUrl: Uri.parse('https://example.com/vet-summary.pdf'),
    storagePath: 'users/user-1/pets/pet-1/exports/vet_summary.pdf',
  );
}

class _FakeFirestoreVetSummaryExportDataSource
    implements FirestoreVetSummaryExportDataSource {
  _FakeFirestoreVetSummaryExportDataSource({
    this.watchedExports = const [],
    this.foundExport,
  });

  final List<VetSummaryExport> watchedExports;
  final VetSummaryExport? foundExport;

  String? watchedUserId;
  String? watchedPetId;
  String? getUserId;
  String? getPetId;
  String? getExportId;
  VetSummaryExport? savedExport;
  String? deletedUserId;
  String? deletedPetId;
  String? deletedExportId;

  @override
  Future<void> deleteExport({
    required String userId,
    required String petId,
    required String exportId,
  }) async {
    deletedUserId = userId;
    deletedPetId = petId;
    deletedExportId = exportId;
  }

  @override
  Future<VetSummaryExport?> getExport({
    required String userId,
    required String petId,
    required String exportId,
  }) async {
    getUserId = userId;
    getPetId = petId;
    getExportId = exportId;
    return foundExport;
  }

  @override
  Future<void> saveExport(VetSummaryExport summaryExport) async {
    savedExport = summaryExport;
  }

  @override
  Stream<List<VetSummaryExport>> watchExports({
    required String userId,
    required String petId,
  }) {
    watchedUserId = userId;
    watchedPetId = petId;
    return Stream<List<VetSummaryExport>>.value(watchedExports);
  }
}
