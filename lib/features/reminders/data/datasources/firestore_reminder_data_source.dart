import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';

abstract interface class FirestoreReminderDataSource {
  Stream<List<Reminder>> watchReminders({
    required String userId,
    required String petId,
  });

  Future<Reminder?> getReminder({
    required String userId,
    required String petId,
    required String reminderId,
  });

  Future<void> saveReminder(Reminder reminder);

  Future<void> completeReminder({
    required String userId,
    required String petId,
    required String reminderId,
  });

  Future<void> deleteReminder({
    required String userId,
    required String petId,
    required String reminderId,
  });
}
