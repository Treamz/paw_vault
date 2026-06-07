import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/vet_summary_export/data/mappers/vet_summary_export_firestore_mapper.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_export.dart';

void main() {
  group('VetSummaryExportFirestoreMapper', () {
    test('maps a complete VetSummaryExport to Firestore data', () {
      final summaryExport = _summaryExport();

      final data = VetSummaryExportFirestoreMapper.toFirestore(summaryExport);

      expect(data['userId'], 'user-1');
      expect(data['petId'], 'pet-1');
      expect(data['fileUrl'], 'https://example.com/vet-summary.pdf');
      expect(data['storagePath'],
          'users/user-1/pets/pet-1/exports/vet_summary.pdf');
      expect(data['createdAt'], isA<Timestamp>());
    });

    test('maps Firestore data to a complete VetSummaryExport', () {
      final data = VetSummaryExportFirestoreMapper.toFirestore(
        _summaryExport(),
      );

      final summaryExport = VetSummaryExportFirestoreMapper.fromFirestore(
        id: const EntityId('export-1'),
        data: data,
      );

      expect(summaryExport.id, const EntityId('export-1'));
      expect(summaryExport.userId, const EntityId('user-1'));
      expect(summaryExport.petId, const EntityId('pet-1'));
      expect(
        summaryExport.fileUrl,
        Uri.parse('https://example.com/vet-summary.pdf'),
      );
      expect(
        summaryExport.storagePath,
        'users/user-1/pets/pet-1/exports/vet_summary.pdf',
      );
      expect(
        summaryExport.createdAt,
        UtcDateTime(DateTime.utc(2026, 1, 2, 3, 4)),
      );
    });

    test('round-trips a complete VetSummaryExport through Firestore data', () {
      final original = _summaryExport();

      final roundTripped = VetSummaryExportFirestoreMapper.fromFirestore(
        id: original.id,
        data: VetSummaryExportFirestoreMapper.toFirestore(original),
      );

      expect(roundTripped.id, original.id);
      expect(roundTripped.userId, original.userId);
      expect(roundTripped.petId, original.petId);
      expect(roundTripped.fileUrl, original.fileUrl);
      expect(roundTripped.storagePath, original.storagePath);
      expect(roundTripped.createdAt, original.createdAt);
    });

    test('uses defaults for missing optional fields', () {
      final summaryExport = VetSummaryExportFirestoreMapper.fromFirestore(
        id: const EntityId('export-1'),
        data: {
          'userId': 'user-1',
          'petId': 'pet-1',
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2, 3, 4)),
        },
      );

      expect(summaryExport.fileUrl, isNull);
      expect(summaryExport.storagePath, isNull);
    });

    test('rejects invalid required fields', () {
      expect(
        () => VetSummaryExportFirestoreMapper.fromFirestore(
          id: const EntityId('export-1'),
          data: const {
            'userId': 'user-1',
            'petId': 'pet-1',
            'createdAt': '2026-01-02T03:04:00Z',
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });

    test('rejects invalid optional storage path', () {
      expect(
        () => VetSummaryExportFirestoreMapper.fromFirestore(
          id: const EntityId('export-1'),
          data: {
            'userId': 'user-1',
            'petId': 'pet-1',
            'storagePath': 42,
            'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2, 3, 4)),
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });
  });
}

VetSummaryExport _summaryExport() {
  return VetSummaryExport(
    id: const EntityId('export-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    fileUrl: Uri.parse('https://example.com/vet-summary.pdf'),
    storagePath: 'users/user-1/pets/pet-1/exports/vet_summary.pdf',
    createdAt: UtcDateTime(DateTime.utc(2026, 1, 2, 3, 4)),
  );
}
