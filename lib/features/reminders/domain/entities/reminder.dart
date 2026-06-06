import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';

enum ReminderRepeatType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

class Reminder {
  const Reminder({
    required this.id,
    required this.userId,
    required this.petId,
    required this.title,
    required this.dateTime,
    this.description,
    this.repeatType,
    this.relatedEventId,
    this.isCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  final EntityId id;
  final EntityId userId;
  final EntityId petId;
  final String title;
  final String? description;
  final UtcDateTime dateTime;
  final ReminderRepeatType? repeatType;
  final EntityId? relatedEventId;
  final bool isCompleted;
  final UtcDateTime? createdAt;
  final UtcDateTime? updatedAt;
}
