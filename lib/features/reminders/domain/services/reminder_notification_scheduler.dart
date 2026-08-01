import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';

/// A tapped reminder notification, identifying the reminder to open.
class ReminderNotificationTap {
  const ReminderNotificationTap({
    required this.petId,
    required this.reminderId,
  });

  final String petId;
  final String reminderId;
}

/// Port for scheduling and cancelling local reminder notifications.
///
/// Implementations live in the data layer and wrap the platform notifications
/// plugin; the presentation layer depends only on this abstraction.
abstract interface class ReminderNotificationScheduler {
  /// Schedules a local notification for [reminder]'s due time. Implementations
  /// should skip completed or past-due reminders and replace any existing
  /// notification for the same reminder.
  Future<void> schedule(Reminder reminder);

  /// Cancels any pending notification for the reminder with [reminderId].
  Future<void> cancel(EntityId reminderId);

  /// Emits when the user taps a reminder notification (including the tap
  /// that launched the app).
  Stream<ReminderNotificationTap> get taps;
}
