import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/documents/domain/entities/pet_document.dart';

abstract final class PetDocumentFirestoreMapper {
  static Map<String, Object?> toFirestore(PetDocument document) {
    return {
      'userId': FirestoreMapping.entityIdToJson(document.userId),
      'petId': FirestoreMapping.entityIdToJson(document.petId),
      'title': document.title,
      'type': FirestoreMapping.enumToJson(document.type),
      if (document.fileUrl != null)
        'fileUrl': FirestoreMapping.uriToJson(document.fileUrl!),
      if (document.storagePath != null) 'storagePath': document.storagePath,
      if (document.extractedText != null)
        'extractedText': document.extractedText,
      'extractedData': document.extractedData,
      if (document.issueDate != null)
        'issueDate': FirestoreMapping.dateOnlyToJson(document.issueDate!),
      if (document.expiryDate != null)
        'expiryDate': FirestoreMapping.dateOnlyToJson(document.expiryDate!),
      if (document.notes != null) 'notes': document.notes,
      if (document.linkedEventId != null)
        'linkedEventId': FirestoreMapping.entityIdToJson(
          document.linkedEventId!,
        ),
      if (document.createdAt != null)
        'createdAt': FirestoreMapping.utcDateTimeToJson(document.createdAt!),
      if (document.updatedAt != null)
        'updatedAt': FirestoreMapping.utcDateTimeToJson(document.updatedAt!),
    };
  }

  static PetDocument fromFirestore({
    required EntityId id,
    required Map<String, Object?> data,
  }) {
    return PetDocument(
      id: id,
      userId: FirestoreMapping.entityIdFromJson(data['userId'], 'userId'),
      petId: FirestoreMapping.entityIdFromJson(data['petId'], 'petId'),
      title: _stringFromFirestore(data['title'], 'title'),
      type: FirestoreMapping.enumFromJson(
        data['type'],
        'type',
        PetDocumentType.values,
      ),
      fileUrl: data['fileUrl'] == null
          ? null
          : FirestoreMapping.uriFromJson(data['fileUrl'], 'fileUrl'),
      storagePath: _optionalStringFromFirestore(
        data['storagePath'],
        'storagePath',
      ),
      extractedText: _optionalStringFromFirestore(
        data['extractedText'],
        'extractedText',
      ),
      extractedData: _mapFromFirestore(data['extractedData'], 'extractedData'),
      issueDate: data['issueDate'] == null
          ? null
          : FirestoreMapping.dateOnlyFromJson(data['issueDate'], 'issueDate'),
      expiryDate: data['expiryDate'] == null
          ? null
          : FirestoreMapping.dateOnlyFromJson(data['expiryDate'], 'expiryDate'),
      notes: _optionalStringFromFirestore(data['notes'], 'notes'),
      linkedEventId: data['linkedEventId'] == null
          ? null
          : FirestoreMapping.entityIdFromJson(
              data['linkedEventId'],
              'linkedEventId',
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
}
