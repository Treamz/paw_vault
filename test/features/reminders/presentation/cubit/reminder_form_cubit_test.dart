import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/reminders/domain/services/reminder_notification_scheduler.dart';
import 'package:paw_vault/features/reminders/presentation/cubit/reminder_form_cubit.dart';
import 'package:paw_vault/features/reminders/presentation/models/reminder_form_state.dart';

void main() {
  group('ReminderFormCubit', () {
    test('createReminder validates, saves, schedules, and emits ready',
        () async {
      final repository = _FakeReminderRepository();
      final scheduler = _FakeNotificationScheduler();
      final cubit = _cubit(repository, scheduler: scheduler);

      await cubit.createReminder(
        'pet-1',
        ReminderFormState(
          title: 'Vaccination due',
          dateTime: DateTime(2027, 1, 10, 9),
          repeatType: ReminderRepeatType.yearly,
        ),
      );

      final saved = repository.savedReminder;
      expect(saved, isNotNull);
      expect(saved!.title, 'Vaccination due');
      expect(saved.petId, const EntityId('pet-1'));
      expect(saved.userId, const EntityId('user-1'));
      expect(saved.repeatType, ReminderRepeatType.yearly);
      expect(cubit.state.status, ReminderFormStatus.ready);
      expect(cubit.state.reminder, saved);
      expect(scheduler.scheduledReminder?.id, saved.id);

      await cubit.close();
    });

    test('createReminder rejects invalid input without saving', () async {
      final repository = _FakeReminderRepository();
      final cubit = _cubit(repository);

      await cubit.createReminder(
        'pet-1',
        const ReminderFormState(title: ''),
      );

      expect(cubit.state.status, ReminderFormStatus.failure);
      expect(repository.saveCallCount, isZero);

      await cubit.close();
    });

    test('createReminder emits failure when saving throws', () async {
      final repository = _FakeReminderRepository(throwsOnSave: true);
      final cubit = _cubit(repository);

      await cubit.createReminder(
        'pet-1',
        ReminderFormState(
          title: 'Vaccination due',
          dateTime: DateTime(2027, 1, 10),
        ),
      );

      expect(cubit.state.status, ReminderFormStatus.failure);
      expect(cubit.state.errorMessage, contains('save failed'));

      await cubit.close();
    });

    test('load then updateReminder saves edited fields', () async {
      final existing = _reminder();
      final repository = _FakeReminderRepository(reminder: existing);
      final cubit = _cubit(repository);

      await cubit.load('pet-1', 'r-1');
      expect(cubit.state.status, ReminderFormStatus.ready);

      await cubit.updateReminder(
        ReminderFormState(
          title: 'Updated title',
          dateTime: DateTime(2027, 2, 1, 10),
        ),
      );

      final saved = repository.savedReminder;
      expect(cubit.state.status, ReminderFormStatus.ready);
      expect(saved!.id, existing.id);
      expect(saved.title, 'Updated title');
      expect(saved.isCompleted, existing.isCompleted);
      expect(saved.createdAt, existing.createdAt);

      await cubit.close();
    });

    test('updateReminder fails when no reminder is loaded', () async {
      final repository = _FakeReminderRepository();
      final cubit = _cubit(repository);

      await cubit.updateReminder(
        ReminderFormState(
          title: 'Updated title',
          dateTime: DateTime(2027, 2, 1),
        ),
      );

      expect(cubit.state.status, ReminderFormStatus.failure);
      expect(repository.saveCallCount, isZero);

      await cubit.close();
    });

    test('load emits notFound when the reminder does not exist', () async {
      final repository = _FakeReminderRepository();
      final cubit = _cubit(repository);

      await cubit.load('pet-1', 'missing');

      expect(cubit.state.status, ReminderFormStatus.notFound);

      await cubit.close();
    });

    test('completeReminder marks complete and cancels the notification',
        () async {
      final repository = _FakeReminderRepository(reminder: _reminder());
      final scheduler = _FakeNotificationScheduler();
      final cubit = _cubit(repository, scheduler: scheduler);

      await cubit.load('pet-1', 'r-1');
      await cubit.completeReminder();

      expect(repository.completeCallCount, 1);
      expect(repository.completedReminderId, const EntityId('r-1'));
      expect(cubit.state.status, ReminderFormStatus.ready);
      expect(cubit.state.reminder?.isCompleted, isTrue);
      expect(scheduler.cancelledId, const EntityId('r-1'));

      await cubit.close();
    });

    test('completeReminder fails when no reminder is loaded', () async {
      final repository = _FakeReminderRepository();
      final cubit = _cubit(repository);

      await cubit.completeReminder();

      expect(cubit.state.status, ReminderFormStatus.failure);
      expect(repository.completeCallCount, isZero);

      await cubit.close();
    });

    test('deleteReminder removes the reminder, clears it, and cancels',
        () async {
      final existing = _reminder();
      final repository = _FakeReminderRepository(reminder: existing);
      final scheduler = _FakeNotificationScheduler();
      final cubit = _cubit(repository, scheduler: scheduler);

      await cubit.load('pet-1', 'r-1');
      await cubit.deleteReminder();

      expect(repository.deleteCallCount, 1);
      expect(repository.deletedReminderId, existing.id);
      expect(cubit.state.status, ReminderFormStatus.ready);
      expect(cubit.state.reminder, isNull);
      expect(scheduler.cancelledId, existing.id);

      await cubit.close();
    });

    test('deleteReminder fails when no reminder is loaded', () async {
      final repository = _FakeReminderRepository();
      final cubit = _cubit(repository);

      await cubit.deleteReminder();

      expect(cubit.state.status, ReminderFormStatus.failure);
      expect(repository.deleteCallCount, isZero);

      await cubit.close();
    });
  });
}

ReminderFormCubit _cubit(
  _FakeReminderRepository repository, {
  _FakeNotificationScheduler? scheduler,
}) {
  return ReminderFormCubit(
    reminderRepository: repository,
    authRepository: _FakeAuthRepository(
      currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
    ),
    notificationScheduler: scheduler ?? _FakeNotificationScheduler(),
  );
}

Reminder _reminder() {
  return Reminder(
    id: const EntityId('r-1'),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    title: 'Original',
    dateTime: UtcDateTime(DateTime(2027, 1, 10, 9)),
    createdAt: UtcDateTime(DateTime(2026, 1, 1)),
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.currentUserValue});

  final AppUser? currentUserValue;

  @override
  Future<AppUser?> currentUser() async => currentUserValue;

  @override
  Future<AppUser> signInAnonymously() async =>
      const AppUser(id: 'signed-in-user', isAnonymous: true);

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() =>
      Stream<AppUser?>.value(currentUserValue);
}

class _FakeReminderRepository implements ReminderRepository {
  _FakeReminderRepository({
    this.reminder,
    this.throwsOnSave = false,
  });

  final Reminder? reminder;
  final bool throwsOnSave;

  int saveCallCount = 0;
  Reminder? savedReminder;
  int completeCallCount = 0;
  EntityId? completedReminderId;
  int deleteCallCount = 0;
  EntityId? deletedReminderId;

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<Reminder>> watchReminders({
    required EntityId userId,
    required EntityId petId,
  }) =>
      const Stream<List<Reminder>>.empty();

  @override
  Future<Reminder?> getReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async =>
      reminder;

  @override
  Future<void> saveReminder(Reminder reminder) async {
    saveCallCount++;
    if (throwsOnSave) {
      throw StateError('save failed');
    }
    savedReminder = reminder;
  }

  @override
  Future<void> completeReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async {
    completeCallCount++;
    completedReminderId = reminderId;
  }

  @override
  Future<void> deleteReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async {
    deleteCallCount++;
    deletedReminderId = reminderId;
  }
}

class _FakeNotificationScheduler implements ReminderNotificationScheduler {
  Reminder? scheduledReminder;
  EntityId? cancelledId;

  @override
  Future<void> schedule(Reminder reminder) async {
    scheduledReminder = reminder;
  }

  @override
  Future<void> cancel(EntityId reminderId) async {
    cancelledId = reminderId;
  }
}
