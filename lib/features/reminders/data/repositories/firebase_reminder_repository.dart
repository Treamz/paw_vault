import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/reminders/data/datasources/firestore_reminder_data_source.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';

class FirebaseReminderRepository implements ReminderRepository {
  const FirebaseReminderRepository(this._dataSource);

  final FirestoreReminderDataSource _dataSource;

  @override
  Future<void> completeReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) {
    return _dataSource.completeReminder(
      userId: userId.value,
      petId: petId.value,
      reminderId: reminderId.value,
    );
  }

  @override
  Future<void> deleteReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) {
    return _dataSource.deleteReminder(
      userId: userId.value,
      petId: petId.value,
      reminderId: reminderId.value,
    );
  }

  @override
  Future<Reminder?> getReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) {
    return _dataSource.getReminder(
      userId: userId.value,
      petId: petId.value,
      reminderId: reminderId.value,
    );
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveReminder(Reminder reminder) {
    return _dataSource.saveReminder(reminder);
  }

  @override
  Stream<List<Reminder>> watchReminders({
    required EntityId userId,
    required EntityId petId,
  }) {
    return _dataSource.watchReminders(
      userId: userId.value,
      petId: petId.value,
    );
  }
}
