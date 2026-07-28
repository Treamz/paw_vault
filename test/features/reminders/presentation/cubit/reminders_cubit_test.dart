import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/reminders/domain/services/reminder_notification_scheduler.dart';
import 'package:paw_vault/features/reminders/presentation/cubit/reminders_cubit.dart';

void main() {
  group('RemindersCubit', () {
    test('loads the current user and emits watched reminders', () async {
      final reminder = _reminder();
      final authRepository = _FakeAuthRepository(
        currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
      );
      final reminderRepository =
          _FakeReminderRepository(watchedReminders: [reminder]);
      final cubit = RemindersCubit(
        reminderRepository: reminderRepository,
        authRepository: authRepository,
        notificationScheduler: _FakeNotificationScheduler(),
      );

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(reminderRepository.initializeCallCount, 1);
      expect(reminderRepository.watchedUserId, const EntityId('user-1'));
      expect(reminderRepository.watchedPetId, const EntityId('pet-1'));
      expect(cubit.state.status, RemindersStatus.ready);
      expect(cubit.state.reminders, [reminder]);

      await cubit.close();
    });

    test('signs in anonymously when no current user exists', () async {
      final authRepository = _FakeAuthRepository(
        signedInUser: const AppUser(id: 'anon', isAnonymous: true),
      );
      final reminderRepository = _FakeReminderRepository();
      final cubit = RemindersCubit(
        reminderRepository: reminderRepository,
        authRepository: authRepository,
        notificationScheduler: _FakeNotificationScheduler(),
      );

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(authRepository.signInAnonymouslyCallCount, 1);
      expect(reminderRepository.watchedUserId, const EntityId('anon'));
      expect(cubit.state.status, RemindersStatus.ready);

      await cubit.close();
    });

    test('emits failure when loading throws', () async {
      final cubit = RemindersCubit(
        reminderRepository: _FakeReminderRepository(throwsOnInitialize: true),
        authRepository: _FakeAuthRepository(),
        notificationScheduler: _FakeNotificationScheduler(),
      );

      await cubit.load('pet-1');

      expect(cubit.state.status, RemindersStatus.failure);
      expect(cubit.state.errorMessage, contains('initialize failed'));

      await cubit.close();
    });

    test('emits failure when the stream errors', () async {
      final cubit = RemindersCubit(
        reminderRepository: _FakeReminderRepository(throwsOnWatch: true),
        authRepository: _FakeAuthRepository(
          currentUserValue: const AppUser(id: 'user-1', isAnonymous: true),
        ),
        notificationScheduler: _FakeNotificationScheduler(),
      );

      await cubit.load('pet-1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, RemindersStatus.failure);
      expect(cubit.state.errorMessage, contains('watch failed'));

      await cubit.close();
    });

    test('sortedReminders orders pending by due date then completed last', () {
      final pendingLater = _reminder(
        id: 'r1',
        dateTime: UtcDateTime(DateTime.utc(2026, 3)),
      );
      final pendingSooner = _reminder(
        id: 'r2',
        dateTime: UtcDateTime(DateTime.utc(2026)),
      );
      final done = _reminder(
        id: 'r3',
        dateTime: UtcDateTime(DateTime.utc(2026, 2)),
        isCompleted: true,
      );
      const state = RemindersState(
        status: RemindersStatus.ready,
      );
      final sorted = RemindersState(
        status: RemindersStatus.ready,
        reminders: [pendingLater, done, pendingSooner],
      ).sortedReminders;

      expect(sorted.map((r) => r.id.value), ['r2', 'r1', 'r3']);
      expect(state.reminders, isEmpty);
    });

    test(
        'toggleCompleted completes a pending reminder and cancels its '
        'notification', () async {
      final reminderRepository = _FakeReminderRepository();
      final scheduler = _FakeNotificationScheduler();
      final cubit = RemindersCubit(
        reminderRepository: reminderRepository,
        authRepository: _FakeAuthRepository(),
        notificationScheduler: scheduler,
      );
      final reminder = _reminder();

      await cubit.toggleCompleted(reminder);

      expect(reminderRepository.completedReminderId, reminder.id);
      expect(scheduler.cancelledId, reminder.id);
      expect(reminderRepository.savedReminder, isNull);

      await cubit.close();
    });

    test('toggleCompleted reopens a completed reminder and reschedules it',
        () async {
      final reminderRepository = _FakeReminderRepository();
      final scheduler = _FakeNotificationScheduler();
      final cubit = RemindersCubit(
        reminderRepository: reminderRepository,
        authRepository: _FakeAuthRepository(),
        notificationScheduler: scheduler,
      );
      final reminder = _reminder(isCompleted: true);

      await cubit.toggleCompleted(reminder);

      expect(reminderRepository.completedReminderId, isNull);
      final saved = reminderRepository.savedReminder;
      expect(saved, isNotNull);
      expect(saved!.id, reminder.id);
      expect(saved.isCompleted, isFalse);
      expect(scheduler.scheduledReminder?.id, reminder.id);

      await cubit.close();
    });
  });
}

Reminder _reminder({
  String id = 'reminder-1',
  UtcDateTime? dateTime,
  bool isCompleted = false,
}) {
  return Reminder(
    id: EntityId(id),
    userId: const EntityId('user-1'),
    petId: const EntityId('pet-1'),
    title: 'Vaccination due',
    dateTime: dateTime ?? UtcDateTime(DateTime.utc(2026, 1, 15)),
    isCompleted: isCompleted,
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.currentUserValue,
    this.signedInUser = const AppUser(id: 'signed-in-user', isAnonymous: true),
  });

  final AppUser? currentUserValue;
  final AppUser signedInUser;

  int signInAnonymouslyCallCount = 0;

  @override
  Future<AppUser?> currentUser() async => currentUserValue;

  @override
  Future<AppUser> signInAnonymously() async {
    signInAnonymouslyCallCount++;
    return signedInUser;
  }

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() =>
      Stream<AppUser?>.value(currentUserValue);
}

class _FakeReminderRepository implements ReminderRepository {
  _FakeReminderRepository({
    this.watchedReminders = const [],
    this.throwsOnInitialize = false,
    this.throwsOnWatch = false,
  });

  final List<Reminder> watchedReminders;
  final bool throwsOnInitialize;
  final bool throwsOnWatch;

  int initializeCallCount = 0;
  EntityId? watchedUserId;
  EntityId? watchedPetId;

  @override
  Future<void> initialize() async {
    initializeCallCount++;
    if (throwsOnInitialize) {
      throw StateError('initialize failed');
    }
  }

  @override
  Stream<List<Reminder>> watchReminders({
    required EntityId userId,
    required EntityId petId,
  }) {
    watchedUserId = userId;
    watchedPetId = petId;
    if (throwsOnWatch) {
      return Stream<List<Reminder>>.error(StateError('watch failed'));
    }
    return Stream<List<Reminder>>.value(watchedReminders);
  }

  @override
  Future<Reminder?> getReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async =>
      null;

  Reminder? savedReminder;
  EntityId? completedReminderId;

  @override
  Future<void> saveReminder(Reminder reminder) async {
    savedReminder = reminder;
  }

  @override
  Future<void> completeReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async {
    completedReminderId = reminderId;
  }

  @override
  Future<void> deleteReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async {}
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
