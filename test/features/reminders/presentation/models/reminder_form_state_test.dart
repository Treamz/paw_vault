import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/presentation/models/reminder_form_state.dart';

void main() {
  group('ReminderFormState', () {
    test('is valid with title and date/time set', () {
      final form = ReminderFormState(
        title: 'Annual vaccination',
        dateTime: DateTime(2027, 1, 10, 9),
      );

      expect(form.validate().isValid, isTrue);
    });

    test('requires a non-empty title', () {
      final form = ReminderFormState(
        title: '   ',
        dateTime: DateTime(2027, 1, 10),
      );

      expect(form.validate().errorFor('title'), isNotNull);
    });

    test('rejects a title longer than 200 characters', () {
      final form = ReminderFormState(
        title: 'a' * 201,
        dateTime: DateTime(2027, 1, 10),
      );

      expect(form.validate().errorFor('title'), isNotNull);
    });

    test('requires a date/time', () {
      const form = ReminderFormState(title: 'Vaccination');

      expect(form.validate().errorFor('dateTime'), isNotNull);
    });

    test('rejects a date more than 10 years in the future', () {
      final form = ReminderFormState(
        title: 'Vaccination',
        dateTime: DateTime(3000),
      );

      expect(form.validate().errorFor('dateTime'), isNotNull);
    });

    test('rejects a description longer than 2000 characters', () {
      final form = ReminderFormState(
        title: 'Vaccination',
        dateTime: DateTime(2027, 1, 10),
        description: 'n' * 2001,
      );

      expect(form.validate().errorFor('description'), isNotNull);
    });

    test('toReminder throws when invalid', () {
      const form = ReminderFormState();

      expect(
        () => form.toReminder(
          id: const EntityId('r-1'),
          userId: const EntityId('user-1'),
          petId: const EntityId('pet-1'),
        ),
        throwsA(isA<ReminderFormValidationException>()),
      );
    });

    test('toReminder builds a trimmed reminder and drops none repeat', () {
      final form = ReminderFormState(
        title: '  Heartworm pill  ',
        dateTime: DateTime(2027, 1, 10, 8, 30),
        description: '  monthly dose  ',
      );

      final reminder = form.toReminder(
        id: const EntityId('r-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
      );

      expect(reminder.title, 'Heartworm pill');
      expect(reminder.description, 'monthly dose');
      expect(reminder.dateTime, UtcDateTime(DateTime(2027, 1, 10, 8, 30)));
      // none maps to null so the entity records "no repeat".
      expect(reminder.repeatType, isNull);
      expect(reminder.isCompleted, isFalse);
    });

    test('toReminder keeps a non-none repeat type', () {
      final form = ReminderFormState(
        title: 'Heartworm pill',
        dateTime: DateTime(2027, 1, 10),
        repeatType: ReminderRepeatType.monthly,
      );

      final reminder = form.toReminder(
        id: const EntityId('r-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
      );

      expect(reminder.repeatType, ReminderRepeatType.monthly);
    });

    test('fromReminder round-trips editable fields', () {
      final reminder = Reminder(
        id: const EntityId('r-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        title: 'Vaccination',
        dateTime: UtcDateTime(DateTime(2027, 1, 10, 9)),
        repeatType: ReminderRepeatType.yearly,
        description: 'rabies booster',
      );

      final form = ReminderFormState.fromReminder(reminder);

      expect(form.title, 'Vaccination');
      expect(form.dateTime, DateTime(2027, 1, 10, 9).toUtc());
      expect(form.repeatType, ReminderRepeatType.yearly);
      expect(form.description, 'rabies booster');
      expect(form.validate().isValid, isTrue);
    });
  });
}
