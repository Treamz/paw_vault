import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';
import 'package:paw_vault/features/timeline/domain/services/event_photo_picker.dart';

class PetEventFormState {
  const PetEventFormState({
    this.type,
    this.title = '',
    this.date,
    this.description,
    this.nextReminderDate,
    this.attachments = const [],
    this.pendingPhotos = const [],
  });

  factory PetEventFormState.fromEvent(PetEvent event) {
    return PetEventFormState(
      type: event.type,
      title: event.title,
      date: event.date.value,
      description: event.description,
      nextReminderDate: event.nextReminderDate?.value,
      attachments: event.attachments.map((uri) => uri.toString()).toList(),
    );
  }

  final PetEventType? type;
  final String title;
  final DateTime? date;
  final String? description;
  final DateTime? nextReminderDate;

  /// Attachment URLs already stored on the event (or produced by an upload).
  /// Never user-typed.
  final List<String> attachments;

  /// Freshly picked photos awaiting upload on save.
  final List<PickedEventPhoto> pendingPhotos;

  PetEventFormState copyWith({
    PetEventType? type,
    String? title,
    DateTime? date,
    String? description,
    DateTime? nextReminderDate,
    List<String>? attachments,
    List<PickedEventPhoto>? pendingPhotos,
  }) {
    return PetEventFormState(
      type: type ?? this.type,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      nextReminderDate: nextReminderDate ?? this.nextReminderDate,
      attachments: attachments ?? this.attachments,
      pendingPhotos: pendingPhotos ?? this.pendingPhotos,
    );
  }

  PetEventFormValidation validate() {
    final errors = <String, String>{};

    if (type == null) {
      errors['type'] = 'Event type is required';
    }

    if (title.trim().isEmpty) {
      errors['title'] = 'Event title is required';
    } else if (title.trim().length > 200) {
      errors['title'] = 'Event title must be 200 characters or less';
    }

    if (date == null) {
      errors['date'] = 'Event date is required';
    } else {
      final now = DateTime.now();
      final hundredYearsAgo = DateTime(now.year - 100);
      final oneYearFromNow = DateTime(now.year + 1, now.month, now.day);

      if (date!.isAfter(oneYearFromNow)) {
        errors['date'] = 'Event date cannot be more than 1 year in the future';
      } else if (date!.isBefore(hundredYearsAgo)) {
        errors['date'] = 'Event date cannot be more than 100 years in the past';
      }
    }

    if (description != null && description!.trim().length > 5000) {
      errors['description'] = 'Description must be 5000 characters or less';
    }

    if (nextReminderDate != null) {
      final twoYearsFromNow = DateTime(
        DateTime.now().year + 2,
        DateTime.now().month,
        DateTime.now().day,
      );
      if (nextReminderDate!.isAfter(twoYearsFromNow)) {
        errors['nextReminderDate'] =
            'Reminder date cannot be more than 2 years in the future';
      }
    }

    return PetEventFormValidation(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  PetEvent toEvent({
    required EntityId id,
    required EntityId userId,
    required EntityId petId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final validation = validate();
    if (!validation.isValid) {
      throw PetEventFormValidationException(validation);
    }

    final validAttachments = attachments
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(Uri.tryParse)
        .whereType<Uri>()
        .toList();

    return PetEvent(
      id: id,
      userId: userId,
      petId: petId,
      type: type!,
      title: title.trim(),
      description:
          description?.trim().isEmpty == true ? null : description?.trim(),
      date: UtcDateTime(date!),
      nextReminderDate:
          nextReminderDate != null ? UtcDateTime(nextReminderDate!) : null,
      attachments: validAttachments,
      source: PetEventSource.manual,
      createdAt: createdAt != null ? UtcDateTime(createdAt) : null,
      updatedAt: updatedAt != null ? UtcDateTime(updatedAt) : null,
    );
  }
}

class PetEventFormValidation {
  const PetEventFormValidation({
    required this.isValid,
    required this.errors,
  });

  final bool isValid;
  final Map<String, String> errors;

  String? errorFor(String field) => errors[field];
}

class PetEventFormValidationException implements Exception {
  PetEventFormValidationException(this.validation);

  final PetEventFormValidation validation;

  @override
  String toString() => 'PetEventFormValidationException: ${validation.errors}';
}
