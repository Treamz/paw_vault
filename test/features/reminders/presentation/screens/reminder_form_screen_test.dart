import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/analytics/data/services/noop_analytics_service.dart';
import 'package:paw_vault/core/analytics/domain/services/analytics_service.dart';
import 'package:paw_vault/core/auth/domain/entities/app_user.dart';
import 'package:paw_vault/core/auth/domain/repositories/auth_repository.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:paw_vault/features/reminders/domain/services/reminder_notification_scheduler.dart';
import 'package:paw_vault/features/reminders/presentation/screens/reminder_form_screen.dart';

void main() {
  group('ReminderFormScreen time entry', () {
    testWidgets('the keyboard toggle puts the cursor in the hour field',
        (tester) async {
      // The reported bug: tapping the keyboard icon showed the hour and
      // minute fields but focused neither, so the keyboard stayed shut and
      // the field had to be tapped as well.
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Date & time'));
      await tester.pumpAndSettle();

      // The date picker opens first; accept the pre-selected date.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Now the time picker, on the dial. It has no fields of its own yet;
      // the form behind it has, so scope every find to the dialog.
      expect(_timeFields(), findsNothing);

      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();

      final fields = _timeFields();
      expect(fields, findsNWidgets(2));
      // The hour field is the first of the two.
      final hourField = tester.widget<EditableText>(fields.first);
      expect(
        hourField.focusNode.hasFocus,
        isTrue,
        reason: 'the hour field must hold focus so the keyboard opens '
            'without a second tap',
      );
    });
  });
}

/// The time picker's own text fields. The reminder form behind the dialog has
/// text fields too, so an unscoped `find.byType(EditableText)` picks those up.
Finder _timeFields() => find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(EditableText),
    );

Widget _app() {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: _FakeAuthRepository()),
      RepositoryProvider<AnalyticsService>.value(
        value: const NoopAnalyticsService(),
      ),
      RepositoryProvider<ReminderRepository>.value(
        value: _FakeReminderRepository(),
      ),
      RepositoryProvider<ReminderNotificationScheduler>.value(
        value: _FakeNotificationScheduler(),
      ),
    ],
    child: const MaterialApp(home: ReminderFormScreen(petId: 'pet-1')),
  );
}

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
  @override
  Future<void> initialize() async {}

  @override
  Stream<List<Reminder>> watchReminders({
    required EntityId userId,
    required EntityId petId,
  }) =>
      Stream<List<Reminder>>.value(const []);

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
  Stream<ReminderNotificationTap> get taps =>
      const Stream<ReminderNotificationTap>.empty();

  @override
  Future<void> schedule(Reminder reminder) async {}

  @override
  Future<void> cancel(EntityId reminderId) async {}
}
