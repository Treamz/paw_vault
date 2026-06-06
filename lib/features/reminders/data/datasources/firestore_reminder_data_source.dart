import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';

abstract interface class FirestoreReminderDataSource {
  Stream<List<Reminder>> watchReminders({
    required String userId,
    required String petId,
  });
}
