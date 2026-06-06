import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';

abstract interface class ReminderRepository {
  Future<void> initialize();

  Stream<List<Reminder>> watchReminders({
    required EntityId userId,
    required EntityId petId,
  });

  Future<Reminder?> getReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  });

  Future<void> saveReminder(Reminder reminder);

  Future<void> completeReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  });

  Future<void> deleteReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  });
}
