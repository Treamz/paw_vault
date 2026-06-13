import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/timeline/domain/entities/pet_event.dart';

abstract final class PetEventFirestoreMapper {
  static Map<String, Object?> toFirestore(PetEvent event) {
    return {
      'userId': FirestoreMapping.entityIdToJson(event.userId),
      'petId': FirestoreMapping.entityIdToJson(event.petId),
      'type': FirestoreMapping.enumToJson(event.type),
      'title': event.title,
      if (event.description != null) 'description': event.description,
      'date': FirestoreMapping.utcDateTimeToJson(event.date),
      if (event.nextReminderDate != null)
        'nextReminderDate':
            FirestoreMapping.utcDateTimeToJson(event.nextReminderDate!),
      'attachments': event.attachments.map(FirestoreMapping.uriToJson).toList(),
      'source': FirestoreMapping.enumToJson(event.source),
      if (event.createdAt != null)
        'createdAt': FirestoreMapping.utcDateTimeToJson(event.createdAt!),
      if (event.updatedAt != null)
        'updatedAt': FirestoreMapping.utcDateTimeToJson(event.updatedAt!),
    };
  }

  static PetEvent fromFirestore({
    required EntityId id,
    required Map<String, Object?> data,
  }) {
    return PetEvent(
      id: id,
      userId: FirestoreMapping.entityIdFromJson(data['userId'], 'userId'),
      petId: FirestoreMapping.entityIdFromJson(data['petId'], 'petId'),
      type: FirestoreMapping.enumFromJson(
        data['type'],
        'type',
        PetEventType.values,
      ),
      title: _stringFromFirestore(data['title'], 'title'),
      description: _optionalStringFromFirestore(
        data['description'],
        'description',
      ),
      date: FirestoreMapping.utcDateTimeFromJson(data['date'], 'date'),
      nextReminderDate: data['nextReminderDate'] == null
          ? null
          : FirestoreMapping.utcDateTimeFromJson(
              data['nextReminderDate'],
              'nextReminderDate',
            ),
      attachments: _uriListFromFirestore(data['attachments'], 'attachments'),
      source: FirestoreMapping.enumFromJson(
        data['source'],
        'source',
        PetEventSource.values,
      ),
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

  static List<Uri> _uriListFromFirestore(Object? value, String fieldName) {
    if (value == null) {
      return const [];
    }

    if (value is List) {
      return value
          .map((item) => FirestoreMapping.uriFromJson(item, fieldName))
          .toList();
    }

    throw FirestoreMappingException.expectedType(
      fieldName: fieldName,
      expectedType: 'List<String>',
      actualValue: value,
    );
  }
}
