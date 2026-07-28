import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';

class ReminderFormState {
  const ReminderFormState({
    this.title = '',
    this.dateTime,
    this.repeatType = ReminderRepeatType.none,
    this.customRepeatDays,
    this.description,
  });

  factory ReminderFormState.fromReminder(Reminder reminder) {
    return ReminderFormState(
      title: reminder.title,
      dateTime: reminder.dateTime.value,
      repeatType: reminder.repeatType ?? ReminderRepeatType.none,
      customRepeatDays: reminder.customRepeatDays,
      description: reminder.description,
    );
  }

  final String title;
  final DateTime? dateTime;
  final ReminderRepeatType repeatType;
  final int? customRepeatDays;
  final String? description;

  ReminderFormState copyWith({
    String? title,
    DateTime? dateTime,
    ReminderRepeatType? repeatType,
    int? customRepeatDays,
    String? description,
  }) {
    return ReminderFormState(
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      repeatType: repeatType ?? this.repeatType,
      customRepeatDays: customRepeatDays ?? this.customRepeatDays,
      description: description ?? this.description,
    );
  }

  ReminderFormValidation validate() {
    final errors = <String, String>{};

    if (title.trim().isEmpty) {
      errors['title'] = 'Reminder title is required';
    } else if (title.trim().length > 200) {
      errors['title'] = 'Reminder title must be 200 characters or less';
    }

    if (repeatType == ReminderRepeatType.custom) {
      final days = customRepeatDays;
      if (days == null || days < 1 || days > 365) {
        errors['customRepeatDays'] = 'Enter how often to repeat (1-365 days)';
      }
    }

    if (dateTime == null) {
      errors['dateTime'] = 'Reminder date and time are required';
    } else {
      final now = DateTime.now();
      final tenYearsFromNow = DateTime(now.year + 10, now.month, now.day);
      if (dateTime!.isAfter(tenYearsFromNow)) {
        errors['dateTime'] =
            'Reminder cannot be more than 10 years in the future';
      }
    }

    if (description != null && description!.trim().length > 2000) {
      errors['description'] = 'Description must be 2000 characters or less';
    }

    return ReminderFormValidation(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  Reminder toReminder({
    required EntityId id,
    required EntityId userId,
    required EntityId petId,
    bool isCompleted = false,
    EntityId? relatedEventId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final validation = validate();
    if (!validation.isValid) {
      throw ReminderFormValidationException(validation);
    }

    return Reminder(
      id: id,
      userId: userId,
      petId: petId,
      title: title.trim(),
      description:
          description?.trim().isEmpty == true ? null : description?.trim(),
      dateTime: UtcDateTime(dateTime!),
      repeatType: repeatType == ReminderRepeatType.none ? null : repeatType,
      customRepeatDays:
          repeatType == ReminderRepeatType.custom ? customRepeatDays : null,
      relatedEventId: relatedEventId,
      isCompleted: isCompleted,
      createdAt: createdAt != null ? UtcDateTime(createdAt) : null,
      updatedAt: updatedAt != null ? UtcDateTime(updatedAt) : null,
    );
  }
}

class ReminderFormValidation {
  const ReminderFormValidation({
    required this.isValid,
    required this.errors,
  });

  final bool isValid;
  final Map<String, String> errors;

  String? errorFor(String field) => errors[field];
}

class ReminderFormValidationException implements Exception {
  ReminderFormValidationException(this.validation);

  final ReminderFormValidation validation;

  @override
  String toString() => 'ReminderFormValidationException: ${validation.errors}';
}
