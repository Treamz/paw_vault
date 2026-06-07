import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/reminders/data/mappers/reminder_firestore_mapper.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';

void main() {
  group('ReminderFirestoreMapper', () {
    test('maps a complete Reminder to Firestore data', () {
      final reminder = _reminder();

      final data = ReminderFirestoreMapper.toFirestore(reminder);

      expect(data['userId'], 'user-1');
      expect(data['petId'], 'pet-1');
      expect(data['title'], 'Give medication');
      expect(data['description'], 'Give one tablet with dinner.');
      expect(data['dateTime'], isA<Timestamp>());
      expect(data['repeatType'], 'daily');
      expect(data['relatedEventId'], 'event-1');
      expect(data['isCompleted'], isTrue);
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('maps Firestore data to a complete Reminder', () {
      final data = ReminderFirestoreMapper.toFirestore(_reminder());

      final reminder = ReminderFirestoreMapper.fromFirestore(
        id: const EntityId('reminder-1'),
        data: data,
      );

      expect(reminder.id, const EntityId('reminder-1'));
      expect(reminder.userId, const EntityId('user-1'));
      expect(reminder.petId, const EntityId('pet-1'));
      expect(reminder.title, 'Give medication');
      expect(reminder.description, 'Give one tablet with dinner.');
      expect(reminder.dateTime, UtcDateTime(DateTime.utc(2026, 1, 2, 18)));
      expect(reminder.repeatType, ReminderRepeatType.daily);
      expect(reminder.relatedEventId, const EntityId('event-1'));
      expect(reminder.isCompleted, isTrue);
      expect(reminder.createdAt, UtcDateTime(DateTime.utc(2026, 1, 1, 9)));
      expect(reminder.updatedAt, UtcDateTime(DateTime.utc(2026, 1, 1, 10)));
    });

    test('round-trips a complete Reminder through Firestore data', () {
      final original = _reminder();

      final roundTripped = ReminderFirestoreMapper.fromFirestore(
        id: original.id,
        data: ReminderFirestoreMapper.toFirestore(original),
      );

      expect(roundTripped.id, original.id);
      expect(roundTripped.userId, original.userId);
      expect(roundTripped.petId, original.petId);
      expect(roundTripped.title, original.title);
      expect(roundTripped.description, original.description);
      expect(roundTripped.dateTime, original.dateTime);
      expect(roundTripped.repeatType, original.repeatType);
      expect(roundTripped.relatedEventId, original.relatedEventId);
      expect(roundTripped.isCompleted, original.isCompleted);
      expect(roundTripped.createdAt, original.createdAt);
      expect(roundTripped.updatedAt, original.updatedAt);
    });

    test('uses defaults for missing optional fields', () {
      final reminder = ReminderFirestoreMapper.fromFirestore(
        id: const EntityId('reminder-1'),
        data: {
          'userId': 'user-1',
          'petId': 'pet-1',
          'title': 'Book vet visit',
          'dateTime': Timestamp.fromDate(DateTime.utc(2026, 2, 3, 12)),
        },
      );

      expect(reminder.description, isNull);
      expect(reminder.repeatType, isNull);
      expect(reminder.relatedEventId, isNull);
      expect(reminder.isCompleted, isFalse);
      expect(reminder.createdAt, isNull);
      expect(reminder.updatedAt, isNull);
    });

    test('rejects invalid required fields', () {
      expect(
        () => ReminderFirestoreMapper.fromFirestore(
          id: const EntityId('reminder-1'),
          data: const {
            'userId': 'user-1',
            'petId': 'pet-1',
            'title': 'Book vet visit',
            'dateTime': '2026-02-03T12:00:00Z',
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });

    test('rejects invalid repeat type', () {
      expect(
        () => ReminderFirestoreMapper.fromFirestore(
          id: const EntityId('reminder-1'),
          data: {
            'userId': 'user-1',
            'petId': 'pet-1',
            'title': 'Book vet visit',
            'dateTime': Timestamp.fromDate(DateTime.utc(2026, 2, 3, 12)),
            'repeatType': 'everyOtherDay',
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });

    test('rejects invalid completion flag', () {
      expect(
        () => ReminderFirestoreMapper.fromFirestore(
          id: const EntityId('reminder-1'),
          data: {
            'userId': 'user-1',
            'petId': 'pet-1',
            'title': 'Book vet visit',
            'dateTime': Timestamp.fromDate(DateTime.utc(2026, 2, 3, 12)),
            'isCompleted': 'false',
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });
  });
}

Reminder _reminder() {
  return Reminder(
    id: const EntityId('reminder-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    title: 'Give medication',
    description: 'Give one tablet with dinner.',
    dateTime: UtcDateTime(DateTime.utc(2026, 1, 2, 18)),
    repeatType: ReminderRepeatType.daily,
    relatedEventId: const EntityId('event-1'),
    isCompleted: true,
    createdAt: UtcDateTime(DateTime.utc(2026, 1, 1, 9)),
    updatedAt: UtcDateTime(DateTime.utc(2026, 1, 1, 10)),
  );
}
