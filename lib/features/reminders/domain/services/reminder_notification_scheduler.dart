import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';

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
}
