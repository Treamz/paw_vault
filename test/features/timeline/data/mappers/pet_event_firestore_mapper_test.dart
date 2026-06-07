import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/timeline/data/mappers/pet_event_firestore_mapper.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';

void main() {
  group('PetEventFirestoreMapper', () {
    test('maps a complete PetEvent to Firestore data', () {
      final event = _event();

      final data = PetEventFirestoreMapper.toFirestore(event);

      expect(data['userId'], 'user-1');
      expect(data['petId'], 'pet-1');
      expect(data['type'], 'vaccination');
      expect(data['title'], 'Rabies vaccine');
      expect(data['description'], 'Annual vaccine.');
      expect(data['date'], isA<Timestamp>());
      expect(data['nextReminderDate'], isA<Timestamp>());
      expect(data['attachments'], ['https://example.com/vaccine.pdf']);
      expect(data['source'], 'manual');
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('maps Firestore data to a complete PetEvent', () {
      final data = PetEventFirestoreMapper.toFirestore(_event());

      final event = PetEventFirestoreMapper.fromFirestore(
        id: const EntityId('event-1'),
        data: data,
      );

      expect(event.id, const EntityId('event-1'));
      expect(event.userId, const EntityId('user-1'));
      expect(event.petId, const EntityId('pet-1'));
      expect(event.type, PetEventType.vaccination);
      expect(event.title, 'Rabies vaccine');
      expect(event.description, 'Annual vaccine.');
      expect(event.date, UtcDateTime(DateTime.utc(2026, 1, 2, 3, 4)));
      expect(
        event.nextReminderDate,
        UtcDateTime(DateTime.utc(2027, 1, 2, 3, 4)),
      );
      expect(event.attachments, [Uri.parse('https://example.com/vaccine.pdf')]);
      expect(event.source, PetEventSource.manual);
      expect(event.createdAt, UtcDateTime(DateTime.utc(2026, 1, 2, 3, 5)));
      expect(event.updatedAt, UtcDateTime(DateTime.utc(2026, 1, 2, 3, 6)));
    });

    test('round-trips a complete PetEvent through Firestore data', () {
      final original = _event();

      final roundTripped = PetEventFirestoreMapper.fromFirestore(
        id: original.id,
        data: PetEventFirestoreMapper.toFirestore(original),
      );

      expect(roundTripped.id, original.id);
      expect(roundTripped.userId, original.userId);
      expect(roundTripped.petId, original.petId);
      expect(roundTripped.type, original.type);
      expect(roundTripped.title, original.title);
      expect(roundTripped.description, original.description);
      expect(roundTripped.date, original.date);
      expect(roundTripped.nextReminderDate, original.nextReminderDate);
      expect(roundTripped.attachments, original.attachments);
      expect(roundTripped.source, original.source);
      expect(roundTripped.createdAt, original.createdAt);
      expect(roundTripped.updatedAt, original.updatedAt);
    });

    test('uses defaults for missing optional fields', () {
      final event = PetEventFirestoreMapper.fromFirestore(
        id: const EntityId('event-1'),
        data: {
          'userId': 'user-1',
          'petId': 'pet-1',
          'type': 'symptom',
          'title': 'Vomiting',
          'date': Timestamp.fromDate(DateTime.utc(2026, 1, 2, 3, 4)),
          'source': 'manual',
        },
      );

      expect(event.description, isNull);
      expect(event.nextReminderDate, isNull);
      expect(event.attachments, isEmpty);
      expect(event.createdAt, isNull);
      expect(event.updatedAt, isNull);
    });

    test('rejects invalid required fields', () {
      expect(
        () => PetEventFirestoreMapper.fromFirestore(
          id: const EntityId('event-1'),
          data: {
            'userId': 'user-1',
            'petId': 'pet-1',
            'type': 'unknownType',
            'title': 'Vomiting',
            'date': Timestamp.fromDate(DateTime.utc(2026, 1, 2, 3, 4)),
            'source': 'manual',
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });

    test('rejects invalid attachments', () {
      expect(
        () => PetEventFirestoreMapper.fromFirestore(
          id: const EntityId('event-1'),
          data: {
            'userId': 'user-1',
            'petId': 'pet-1',
            'type': 'symptom',
            'title': 'Vomiting',
            'date': Timestamp.fromDate(DateTime.utc(2026, 1, 2, 3, 4)),
            'attachments': [42],
            'source': 'manual',
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });
  });
}

PetEvent _event() {
  return PetEvent(
    id: const EntityId('event-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    type: PetEventType.vaccination,
    title: 'Rabies vaccine',
    description: 'Annual vaccine.',
    date: UtcDateTime(DateTime.utc(2026, 1, 2, 3, 4)),
    nextReminderDate: UtcDateTime(DateTime.utc(2027, 1, 2, 3, 4)),
    attachments: [Uri.parse('https://example.com/vaccine.pdf')],
    source: PetEventSource.manual,
    createdAt: UtcDateTime(DateTime.utc(2026, 1, 2, 3, 5)),
    updatedAt: UtcDateTime(DateTime.utc(2026, 1, 2, 3, 6)),
  );
}
