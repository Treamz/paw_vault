import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/reminders/domain/entities/reminder.dart';

abstract final class ReminderFirestoreMapper {
  static Map<String, Object?> toFirestore(Reminder reminder) {
    return {
      'userId': FirestoreMapping.entityIdToJson(reminder.userId),
      'petId': FirestoreMapping.entityIdToJson(reminder.petId),
      'title': reminder.title,
      if (reminder.description != null) 'description': reminder.description,
      'dateTime': FirestoreMapping.utcDateTimeToJson(reminder.dateTime),
      if (reminder.repeatType != null)
        'repeatType': FirestoreMapping.enumToJson(reminder.repeatType!),
      if (reminder.relatedEventId != null)
        'relatedEventId': FirestoreMapping.entityIdToJson(
          reminder.relatedEventId!,
        ),
      'isCompleted': reminder.isCompleted,
      if (reminder.createdAt != null)
        'createdAt': FirestoreMapping.utcDateTimeToJson(reminder.createdAt!),
      if (reminder.updatedAt != null)
        'updatedAt': FirestoreMapping.utcDateTimeToJson(reminder.updatedAt!),
    };
  }

  static Reminder fromFirestore({
    required EntityId id,
    required Map<String, Object?> data,
  }) {
    return Reminder(
      id: id,
      userId: FirestoreMapping.entityIdFromJson(data['userId'], 'userId'),
      petId: FirestoreMapping.entityIdFromJson(data['petId'], 'petId'),
      title: _stringFromFirestore(data['title'], 'title'),
      description: _optionalStringFromFirestore(
        data['description'],
        'description',
      ),
      dateTime: FirestoreMapping.utcDateTimeFromJson(
        data['dateTime'],
        'dateTime',
      ),
      repeatType: data['repeatType'] == null
          ? null
          : FirestoreMapping.enumFromJson(
              data['repeatType'],
              'repeatType',
              ReminderRepeatType.values,
            ),
      relatedEventId: data['relatedEventId'] == null
          ? null
          : FirestoreMapping.entityIdFromJson(
              data['relatedEventId'],
              'relatedEventId',
            ),
      isCompleted: _boolFromFirestore(data['isCompleted'], 'isCompleted'),
      createdAt: data['createdAt'] == null
          ? null
          : FirestoreMapping.utcDateTimeFromJson(
              data['createdAt'],
              'createdAt',
            ),
      updatedAt: data['updatedAt'] == null
          ? null
          : FirestoreMapping.utcDateTimeFromJson(
              data['updatedAt'],
              'updatedAt',
            ),
    );
  }

  static String _stringFromFirestore(Object? value, String fieldName) {
    if (value is String) {
      return value;
    }

    throw FirestoreMappingException.expectedType(
      fieldName: fieldName,
      expectedType: 'String',
      actualValue: value,
    );
  }

  static String? _optionalStringFromFirestore(
    Object? value,
    String fieldName,
  ) {
    if (value == null || value is String) {
      return value as String?;
    }

    throw FirestoreMappingException.expectedType(
      fieldName: fieldName,
      expectedType: 'String?',
      actualValue: value,
    );
  }

  static bool _boolFromFirestore(Object? value, String fieldName) {
    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    throw FirestoreMappingException.expectedType(
      fieldName: fieldName,
      expectedType: 'bool',
      actualValue: value,
    );
  }
}
