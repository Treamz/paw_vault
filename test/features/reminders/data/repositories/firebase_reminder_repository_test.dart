import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/reminders/data/datasources/firestore_reminder_data_source.dart';
import 'package:paw_vault/features/reminders/data/repositories/firebase_reminder_repository.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';

void main() {
  group('FirebaseReminderRepository', () {
    test('watches reminders through the Firestore data source', () async {
      final reminder = _reminder();
      final dataSource = _FakeFirestoreReminderDataSource(
        watchedReminders: [
          reminder,
        ],
      );
      final repository = FirebaseReminderRepository(dataSource);

      final reminders = await repository
          .watchReminders(
            userId: const EntityId('user-1'),
            petId: const EntityId('pet-1'),
          )
          .first;

      expect(reminders, [reminder]);
      expect(dataSource.watchedUserId, 'user-1');
      expect(dataSource.watchedPetId, 'pet-1');
    });

    test('gets a reminder through the Firestore data source', () async {
      final reminder = _reminder();
      final dataSource = _FakeFirestoreReminderDataSource(
        foundReminder: reminder,
      );
      final repository = FirebaseReminderRepository(dataSource);

      final result = await repository.getReminder(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        reminderId: const EntityId('reminder-1'),
      );

      expect(result, reminder);
      expect(dataSource.getUserId, 'user-1');
      expect(dataSource.getPetId, 'pet-1');
      expect(dataSource.getReminderId, 'reminder-1');
    });

    test('saves a reminder through the Firestore data source', () async {
      final reminder = _reminder();
      final dataSource = _FakeFirestoreReminderDataSource();
      final repository = FirebaseReminderRepository(dataSource);

      await repository.saveReminder(reminder);

      expect(dataSource.savedReminder, reminder);
    });

    test('completes a reminder through the Firestore data source', () async {
      final dataSource = _FakeFirestoreReminderDataSource();
      final repository = FirebaseReminderRepository(dataSource);

      await repository.completeReminder(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        reminderId: const EntityId('reminder-1'),
      );

      expect(dataSource.completedUserId, 'user-1');
      expect(dataSource.completedPetId, 'pet-1');
      expect(dataSource.completedReminderId, 'reminder-1');
    });

    test('deletes a reminder through the Firestore data source', () async {
      final dataSource = _FakeFirestoreReminderDataSource();
      final repository = FirebaseReminderRepository(dataSource);

      await repository.deleteReminder(
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        reminderId: const EntityId('reminder-1'),
      );

      expect(dataSource.deletedUserId, 'user-1');
      expect(dataSource.deletedPetId, 'pet-1');
      expect(dataSource.deletedReminderId, 'reminder-1');
    });
  });
}

Reminder _reminder() {
  return Reminder(
    id: const EntityId('reminder-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    title: 'Give medication',
    dateTime: UtcDateTime(DateTime.utc(2026, 1, 2, 18)),
  );
}

class _FakeFirestoreReminderDataSource implements FirestoreReminderDataSource {
  _FakeFirestoreReminderDataSource({
    this.watchedReminders = const [],
    this.foundReminder,
  });

  final List<Reminder> watchedReminders;
  final Reminder? foundReminder;

  String? watchedUserId;
  String? watchedPetId;
  String? getUserId;
  String? getPetId;
  String? getReminderId;
  Reminder? savedReminder;
  String? completedUserId;
  String? completedPetId;
  String? completedReminderId;
  String? deletedUserId;
  String? deletedPetId;
  String? deletedReminderId;

  @override
  Future<void> completeReminder({
    required String userId,
    required String petId,
    required String reminderId,
  }) async {
    completedUserId = userId;
    completedPetId = petId;
    completedReminderId = reminderId;
  }

  @override
  Future<void> deleteReminder({
    required String userId,
    required String petId,
    required String reminderId,
  }) async {
    deletedUserId = userId;
    deletedPetId = petId;
    deletedReminderId = reminderId;
  }

  @override
  Future<Reminder?> getReminder({
    required String userId,
    required String petId,
    required String reminderId,
  }) async {
    getUserId = userId;
    getPetId = petId;
    getReminderId = reminderId;
    return foundReminder;
  }

  @override
  Future<void> saveReminder(Reminder reminder) async {
    savedReminder = reminder;
  }

  @override
  Stream<List<Reminder>> watchReminders({
    required String userId,
    required String petId,
  }) {
    watchedUserId = userId;
    watchedPetId = petId;
    return Stream<List<Reminder>>.value(watchedReminders);
  }
}
