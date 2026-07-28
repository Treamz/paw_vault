import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/reminders/domain/services/reminder_notification_scheduler.dart';
import 'package:paw_vault/features/reminders/presentation/screens/reminders_screen.dart';

void main() {
  group('RemindersScreen', () {
    testWidgets('shows the empty state when there are no reminders',
        (tester) async {
      await tester.pumpWidget(_app(const []));
      await tester.pumpAndSettle();

      expect(find.text('No reminders yet'), findsOneWidget);
    });

    testWidgets('renders reminders when present', (tester) async {
      await tester.pumpWidget(_app([_reminder()]));
      await tester.pumpAndSettle();

      expect(find.text('Annual vaccination'), findsOneWidget);
      expect(find.text('No reminders yet'), findsNothing);
    });
  });
}

Widget _app(List<Reminder> reminders) {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: _FakeAuthRepository()),
      RepositoryProvider<ReminderNotificationScheduler>.value(
        value: _FakeNotificationScheduler(),
      ),
      RepositoryProvider<ReminderRepository>.value(
        value: _FakeReminderRepository(reminders),
      ),
    ],
    child: const MaterialApp(home: RemindersScreen(petId: 'pet-1')),
  );
}

Reminder _reminder() => Reminder(
      id: const EntityId('r-1'),
      userId: const EntityId('user-1'),
      petId: const EntityId('pet-1'),
      title: 'Annual vaccination',
      dateTime: UtcDateTime(DateTime.utc(2027, 1, 10, 9)),
    );

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AppUser?> currentUser() async =>
      const AppUser(id: 'user-1', isAnonymous: true);

  @override
  Future<AppUser> signInAnonymously() async =>
      const AppUser(id: 'user-1', isAnonymous: true);

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> watchCurrentUser() => Stream<AppUser?>.value(
        const AppUser(id: 'user-1', isAnonymous: true),
      );
}

class _FakeReminderRepository implements ReminderRepository {
  _FakeReminderRepository(this.reminders);

  final List<Reminder> reminders;

  @override
  Future<void> initialize() async {}

  @override
  Stream<List<Reminder>> watchReminders({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<Reminder>>.value(reminders);

  @override
  Future<Reminder?> getReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async =>
      null;

  @override
  Future<void> saveReminder(Reminder reminder) async {}

  @override
  Future<void> completeReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async {}

  @override
  Future<void> deleteReminder({
    required EntityId userId,
    required EntityId petId,
    required EntityId reminderId,
  }) async {}
}

class _FakeNotificationScheduler implements ReminderNotificationScheduler {
  @override
  Future<void> schedule(Reminder reminder) async {}

  @override
  Future<void> cancel(EntityId reminderId) async {}
}
