import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';
import 'package:paw_vault/features/reminders/domain/services/reminder_notification_scheduler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// [ReminderNotificationScheduler] backed by the `flutter_local_notifications`
/// plugin.
class LocalReminderNotificationScheduler
    implements ReminderNotificationScheduler {
  LocalReminderNotificationScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channelId = 'pawvault_reminders';
  static const _channelName = 'Reminders';
  static const _channelDescription = 'Pet care reminders';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  @override
  Future<void> schedule(Reminder reminder) async {
    await _ensureInitialized();

    if (reminder.isCompleted) {
      await cancel(reminder.id);
      return;
    }

    // The reminder time is stored in UTC, so schedule against the same absolute
    // instant; the OS delivers it at the correct local moment.
    final when = tz.TZDateTime.from(reminder.dateTime.value, tz.UTC);
    if (!when.isAfter(tz.TZDateTime.now(tz.UTC))) {
      // Past-due reminders are not scheduled.
      await cancel(reminder.id);
      return;
    }

    await _plugin.zonedSchedule(
      id: _notificationId(reminder.id),
      title: reminder.title,
      body: reminder.description ?? 'Reminder due',
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(EntityId reminderId) async {
    await _ensureInitialized();
    await _plugin.cancel(id: _notificationId(reminderId));
  }

  /// Maps a string reminder id to a stable positive 31-bit notification id.
  int _notificationId(EntityId reminderId) =>
      reminderId.value.hashCode & 0x7fffffff;
}
