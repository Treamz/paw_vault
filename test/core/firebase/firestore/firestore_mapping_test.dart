import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';

void main() {
  group('FirestoreMapping', () {
    test('maps EntityId to and from a non-empty string', () {
      const id = EntityId('pet-1');

      expect(FirestoreMapping.entityIdToJson(id), 'pet-1');
      expect(
        FirestoreMapping.entityIdFromJson('pet-1', 'petId'),
        const EntityId('pet-1'),
      );
    });

    test('rejects invalid EntityId values', () {
      expect(
        () => FirestoreMapping.entityIdFromJson(' ', 'petId'),
        throwsA(isA<FirestoreMappingException>()),
      );
      expect(
        () => FirestoreMapping.entityIdFromJson(null, 'petId'),
        throwsA(isA<FirestoreMappingException>()),
      );
    });

    test('maps DateOnly to and from an ISO date string', () {
      const date = DateOnly(year: 2026, month: 6, day: 6);

      expect(FirestoreMapping.dateOnlyToJson(date), '2026-06-06');
      expect(
        FirestoreMapping.dateOnlyFromJson('2026-06-06', 'birthDate'),
        date,
      );
    });

    test('rejects invalid DateOnly values', () {
      expect(
        () => FirestoreMapping.dateOnlyFromJson('2026/06/06', 'birthDate'),
        throwsA(isA<FirestoreMappingException>()),
      );
      expect(
        () => FirestoreMapping.dateOnlyFromJson('2026-aa-06', 'birthDate'),
        throwsA(isA<FirestoreMappingException>()),
      );
      expect(
        () => FirestoreMapping.dateOnlyFromJson(123, 'birthDate'),
        throwsA(isA<FirestoreMappingException>()),
      );
    });

    test('maps UtcDateTime to and from Timestamp', () {
      final dateTime = UtcDateTime(DateTime.utc(2026, 6, 6, 10, 30));
      final timestamp = FirestoreMapping.utcDateTimeToJson(dateTime);

      expect(timestamp, isA<Timestamp>());
      expect(
        FirestoreMapping.utcDateTimeFromJson(timestamp, 'createdAt'),
        dateTime,
      );
    });

    test('maps DateTime inputs into UtcDateTime on reads', () {
      final value = FirestoreMapping.utcDateTimeFromJson(
        DateTime.parse('2026-06-06T12:30:00+02:00'),
        'createdAt',
      );

      expect(value.value, DateTime.utc(2026, 6, 6, 10, 30));
    });

    test('rejects invalid UtcDateTime values', () {
      expect(
        () => FirestoreMapping.utcDateTimeFromJson('today', 'createdAt'),
        throwsA(isA<FirestoreMappingException>()),
      );
    });

    test('maps enums to and from stable enum names', () {
      expect(FirestoreMapping.enumToJson(_TestStatus.review), 'review');
      expect(
        FirestoreMapping.enumFromJson(
          'confirmed',
          'status',
          _TestStatus.values,
        ),
        _TestStatus.confirmed,
      );
    });

    test('rejects unknown enum values', () {
      expect(
        () => FirestoreMapping.enumFromJson(
          'missing',
          'status',
          _TestStatus.values,
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });

    test('maps Uri to and from a non-empty string', () {
      final uri = Uri.parse('https://example.com/file.pdf');

      expect(FirestoreMapping.uriToJson(uri), 'https://example.com/file.pdf');
      expect(
        FirestoreMapping.uriFromJson('https://example.com/file.pdf', 'fileUrl'),
        uri,
      );
    });

    test('rejects invalid Uri values', () {
      expect(
        () => FirestoreMapping.uriFromJson('', 'fileUrl'),
        throwsA(isA<FirestoreMappingException>()),
      );
      expect(
        () => FirestoreMapping.uriFromJson(null, 'fileUrl'),
        throwsA(isA<FirestoreMappingException>()),
      );
    });

    test('creates a server timestamp sentinel', () {
      expect(FirestoreMapping.serverTimestamp(), isA<FieldValue>());
    });
  });
}

enum _TestStatus {
  review,
  confirmed,
}
