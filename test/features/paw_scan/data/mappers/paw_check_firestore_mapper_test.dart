import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/paw_scan/data/mappers/paw_check_firestore_mapper.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';

PawCheck _check() {
  return PawCheck(
    id: const EntityId('check-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    location: PawLocation.frontLeft,
    attentionLevel: PawAttentionLevel.vetSoon,
    checkedAt: UtcDateTime(DateTime.utc(2026, 9, 18, 10, 30)),
    photoUrls: [Uri.parse('https://example.com/paw-0.jpg')],
    photoStoragePaths: const [
      'users/user-1/pets/pet-1/pawChecks/check-1/0.jpg',
    ],
    observations: const [
      'A dark area near the centre of the main pad.',
      'The nail on the third digit is longer than the others.',
    ],
    summary: 'One pad looks different from the others.',
    ownerNote: 'She was licking it last night.',
    includeInVetSummary: true,
    confidence: 0.82,
    status: PawCheckStatus.confirmed,
    createdAt: UtcDateTime(DateTime.utc(2026, 9, 18, 10, 31)),
    updatedAt: UtcDateTime(DateTime.utc(2026, 9, 18, 10, 32)),
  );
}

void main() {
  group('PawCheckFirestoreMapper', () {
    test('maps an entity to Firestore data', () {
      final data = PawCheckFirestoreMapper.toFirestore(_check());

      expect(data['userId'], 'user-1');
      expect(data['petId'], 'pet-1');
      expect(data['location'], 'frontLeft');
      expect(data['attentionLevel'], 'vetSoon');
      expect(data['photoUrls'], ['https://example.com/paw-0.jpg']);
      expect(data['observations'], hasLength(2));
      expect(data['summary'], 'One pad looks different from the others.');
      expect(data['ownerNote'], 'She was licking it last night.');
      expect(data['includeInVetSummary'], isTrue);
      expect(data['confidence'], 0.82);
      expect(data['status'], 'confirmed');
      // The id is the document id, never a field.
      expect(data.containsKey('id'), isFalse);
    });

    test('maps Firestore data to an entity', () {
      final check = PawCheckFirestoreMapper.fromFirestore(
        id: const EntityId('check-1'),
        data: {
          'userId': 'user-1',
          'petId': 'pet-1',
          'location': 'rearRight',
          'attentionLevel': 'monitor',
          'checkedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 18, 10, 30)),
          'photoUrls': const ['https://example.com/paw-0.jpg'],
          'photoStoragePaths': const ['users/u/pets/p/pawChecks/c/0.jpg'],
          'observations': const ['A dark area on the pad.'],
          'includeInVetSummary': true,
          'confidence': 0.5,
          'status': 'confirmed',
        },
      );

      expect(check.id, const EntityId('check-1'));
      expect(check.location, PawLocation.rearRight);
      expect(check.attentionLevel, PawAttentionLevel.monitor);
      expect(
        check.photoUrls.single.toString(),
        'https://example.com/paw-0.jpg',
      );
      expect(check.observations.single, 'A dark area on the pad.');
      expect(check.includeInVetSummary, isTrue);
      expect(check.confidence, 0.5);
      expect(check.status, PawCheckStatus.confirmed);
    });

    test('round-trips a complete check through Firestore data', () {
      final original = _check();

      final restored = PawCheckFirestoreMapper.fromFirestore(
        id: original.id,
        data: PawCheckFirestoreMapper.toFirestore(original),
      );

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.petId, original.petId);
      expect(restored.location, original.location);
      expect(restored.attentionLevel, original.attentionLevel);
      expect(restored.checkedAt, original.checkedAt);
      expect(restored.photoUrls, original.photoUrls);
      expect(restored.photoStoragePaths, original.photoStoragePaths);
      expect(restored.observations, original.observations);
      expect(restored.summary, original.summary);
      expect(restored.ownerNote, original.ownerNote);
      expect(restored.includeInVetSummary, original.includeInVetSummary);
      expect(restored.confidence, original.confidence);
      expect(restored.status, original.status);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('uses defaults for missing optional fields', () {
      final check = PawCheckFirestoreMapper.fromFirestore(
        id: const EntityId('check-1'),
        data: {
          'userId': 'user-1',
          'petId': 'pet-1',
          'checkedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 18)),
        },
      );

      expect(check.location, PawLocation.unspecified);
      expect(check.photoUrls, isEmpty);
      expect(check.photoStoragePaths, isEmpty);
      expect(check.observations, isEmpty);
      expect(check.summary, isNull);
      expect(check.ownerNote, isNull);
      expect(check.includeInVetSummary, isFalse);
      expect(check.confidence, 0);
      expect(check.status, PawCheckStatus.confirmed);
    });

    test('a missing attention level never reads as "nothing notable"', () {
      final check = PawCheckFirestoreMapper.fromFirestore(
        id: const EntityId('check-1'),
        data: {
          'userId': 'user-1',
          'petId': 'pet-1',
          'checkedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 18)),
        },
      );

      expect(check.attentionLevel, PawAttentionLevel.undetermined);
      expect(check.attentionLevel, isNot(PawAttentionLevel.nothingNotable));
    });

    test('throws on an unknown attention level', () {
      expect(
        () => PawCheckFirestoreMapper.fromFirestore(
          id: const EntityId('check-1'),
          data: {
            'userId': 'user-1',
            'petId': 'pet-1',
            'checkedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 18)),
            'attentionLevel': 'panic',
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });

    test('throws when a list field is not a list', () {
      expect(
        () => PawCheckFirestoreMapper.fromFirestore(
          id: const EntityId('check-1'),
          data: {
            'userId': 'user-1',
            'petId': 'pet-1',
            'checkedAt': Timestamp.fromDate(DateTime.utc(2026, 9, 18)),
            'observations': 'not a list',
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });
  });
}
