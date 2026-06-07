import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/smart_input/domain/entities/smart_message.dart';

abstract final class SmartMessageFirestoreMapper {
  static Map<String, Object?> toFirestore(SmartMessage message) {
    return {
      'userId': FirestoreMapping.entityIdToJson(message.userId),
      'petId': FirestoreMapping.entityIdToJson(message.petId),
      'originalText': message.originalText,
      'detectedIntent': FirestoreMapping.enumToJson(message.detectedIntent),
      'extractedData': message.extractedData,
      'suggestedActions': message.suggestedActions
          .map(
            (action) => {
              'type': FirestoreMapping.enumToJson(action.type),
              'payload': action.payload,
            },
          )
          .toList(),
      'confidence': message.confidence,
      'status': FirestoreMapping.enumToJson(message.status),
      if (message.createdAt != null)
        'createdAt': FirestoreMapping.utcDateTimeToJson(message.createdAt!),
    };
  }

  static SmartMessage fromFirestore({
    required EntityId id,
    required Map<String, Object?> data,
  }) {
    return SmartMessage(
      id: id,
      userId: FirestoreMapping.entityIdFromJson(data['userId'], 'userId'),
      petId: FirestoreMapping.entityIdFromJson(data['petId'], 'petId'),
      originalText: _stringFromFirestore(data['originalText'], 'originalText'),
      detectedIntent: FirestoreMapping.enumFromJson(
        data['detectedIntent'],
        'detectedIntent',
        SmartMessageIntent.values,
      ),
      extractedData: _mapFromFirestore(data['extractedData'], 'extractedData'),
      suggestedActions: _suggestedActionsFromFirestore(
        data['suggestedActions'],
        'suggestedActions',
      ),
      confidence: _doubleFromFirestore(data['confidence'], 'confidence'),
      status: FirestoreMapping.enumFromJson(
        data['status'],
        'status',
        SmartMessageStatus.values,
      ),
      createdAt: data['createdAt'] == null
          ? null
          : FirestoreMapping.utcDateTimeFromJson(
              data['createdAt'],
              'createdAt',
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

  static double _doubleFromFirestore(Object? value, String fieldName) {
    if (value is num) {
      return value.toDouble();
    }

    throw FirestoreMappingException.expectedType(
      fieldName: fieldName,
      expectedType: 'num',
      actualValue: value,
    );
  }

  static Map<String, Object?> _mapFromFirestore(
    Object? value,
    String fieldName,
  ) {
    if (value == null) {
      return const {};
    }

    if (value is Map) {
      return value.cast<String, Object?>();
    }

    throw FirestoreMappingException.expectedType(
      fieldName: fieldName,
      expectedType: 'Map<String, Object?>',
      actualValue: value,
    );
  }

  static List<SmartSuggestedAction> _suggestedActionsFromFirestore(
    Object? value,
    String fieldName,
  ) {
    if (value == null) {
      return const [];
    }

    if (value is! List) {
      throw FirestoreMappingException.expectedType(
        fieldName: fieldName,
        expectedType: 'List<Map<String, Object?>>',
        actualValue: value,
      );
    }

    return value
        .map((item) => _suggestedActionFromFirestore(item, fieldName))
        .toList();
  }

  static SmartSuggestedAction _suggestedActionFromFirestore(
    Object? value,
    String fieldName,
  ) {
    if (value is! Map) {
      throw FirestoreMappingException.expectedType(
        fieldName: fieldName,
        expectedType: 'Map<String, Object?>',
        actualValue: value,
      );
    }

    final actionData = value.cast<String, Object?>();
    return SmartSuggestedAction(
      type: FirestoreMapping.enumFromJson(
        actionData['type'],
        '$fieldName.type',
        SmartSuggestedActionType.values,
      ),
      payload: _mapFromFirestore(actionData['payload'], '$fieldName.payload'),
    );
  }
}
