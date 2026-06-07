import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/vet_summary_export/domain/entities/vet_summary_export.dart';

abstract final class VetSummaryExportFirestoreMapper {
  static Map<String, Object?> toFirestore(VetSummaryExport summaryExport) {
    return {
      'userId': FirestoreMapping.entityIdToJson(summaryExport.userId),
      'petId': FirestoreMapping.entityIdToJson(summaryExport.petId),
      if (summaryExport.fileUrl != null)
        'fileUrl': FirestoreMapping.uriToJson(summaryExport.fileUrl!),
      if (summaryExport.storagePath != null)
        'storagePath': summaryExport.storagePath,
      'createdAt': FirestoreMapping.utcDateTimeToJson(
        summaryExport.createdAt,
      ),
    };
  }

  static VetSummaryExport fromFirestore({
    required EntityId id,
    required Map<String, Object?> data,
  }) {
    return VetSummaryExport(
      id: id,
      userId: FirestoreMapping.entityIdFromJson(data['userId'], 'userId'),
      petId: FirestoreMapping.entityIdFromJson(data['petId'], 'petId'),
      fileUrl: data['fileUrl'] == null
          ? null
          : FirestoreMapping.uriFromJson(data['fileUrl'], 'fileUrl'),
      storagePath: _optionalStringFromFirestore(
        data['storagePath'],
        'storagePath',
      ),
      createdAt: FirestoreMapping.utcDateTimeFromJson(
        data['createdAt'],
        'createdAt',
      ),
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
}
