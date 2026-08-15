import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/features/reminders/data/services/local_reminder_notification_scheduler.dart';
import 'package:paw_vault/features/reminders/domain/services/reminder_notification_scheduler.dart';

void main() {
  group('LocalReminderNotificationScheduler taps', () {
    test('delivers a tap that arrived before anyone listened', () async {
      final scheduler =
          LocalReminderNotificationScheduler(FlutterLocalNotificationsPlugin());

      // Cold start: the launch-details tap fires before the UI subscribes.
      scheduler.handleNotificationPayload('pet-1|reminder-1');

      final tap = await scheduler.taps.first;
      expect(tap.petId, 'pet-1');
      expect(tap.reminderId, 'reminder-1');
    });

    test('delivers taps live once a listener is attached', () async {
      final scheduler =
          LocalReminderNotificationScheduler(FlutterLocalNotificationsPlugin());
      final received = <ReminderNotificationTap>[];
      final subscription = scheduler.taps.listen(received.add);
      await Future<void>.delayed(Duration.zero);

      scheduler.handleNotificationPayload('pet-2|reminder-9');
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single.petId, 'pet-2');
      expect(received.single.reminderId, 'reminder-9');

      await subscription.cancel();
    });

    test('ignores malformed payloads', () async {
      final scheduler =
          LocalReminderNotificationScheduler(FlutterLocalNotificationsPlugin());
      final received = <ReminderNotificationTap>[];
      final subscription = scheduler.taps.listen(received.add);
      await Future<void>.delayed(Duration.zero);

      scheduler.handleNotificationPayload(null);
      scheduler.handleNotificationPayload('');
      scheduler.handleNotificationPayload('no-separator');
      scheduler.handleNotificationPayload('|reminder');
      scheduler.handleNotificationPayload('pet|');
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);

      await subscription.cancel();
    });
  });
}
