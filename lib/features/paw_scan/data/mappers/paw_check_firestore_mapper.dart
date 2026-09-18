import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_attention_level.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_check.dart';
import 'package:paw_vault/features/paw_scan/domain/entities/paw_location.dart';

abstract final class PawCheckFirestoreMapper {
  static Map<String, Object?> toFirestore(PawCheck check) {
    return {
      'userId': FirestoreMapping.entityIdToJson(check.userId),
      'petId': FirestoreMapping.entityIdToJson(check.petId),
      'location': FirestoreMapping.enumToJson(check.location),
      'attentionLevel': FirestoreMapping.enumToJson(check.attentionLevel),
      'checkedAt': FirestoreMapping.utcDateTimeToJson(check.checkedAt),
      'photoUrls': [
        for (final url in check.photoUrls) FirestoreMapping.uriToJson(url),
      ],
      'photoStoragePaths': check.photoStoragePaths,
      'observations': check.observations,
      if (check.summary != null) 'summary': check.summary,
      if (check.ownerNote != null) 'ownerNote': check.ownerNote,
      'includeInVetSummary': check.includeInVetSummary,
      'confidence': check.confidence,
      'status': FirestoreMapping.enumToJson(check.status),
      if (check.createdAt != null)
        'createdAt': FirestoreMapping.utcDateTimeToJson(check.createdAt!),
      if (check.updatedAt != null)
        'updatedAt': FirestoreMapping.utcDateTimeToJson(check.updatedAt!),
    };
  }

  static PawCheck fromFirestore({
    required EntityId id,
    required Map<String, Object?> data,
  }) {
    return PawCheck(
      id: id,
      userId: FirestoreMapping.entityIdFromJson(data['userId'], 'userId'),
      petId: FirestoreMapping.entityIdFromJson(data['petId'], 'petId'),
      location: data['location'] == null
          ? PawLocation.unspecified
          : FirestoreMapping.enumFromJson(
              data['location'],
              'location',
              PawLocation.values,
            ),
      attentionLevel: data['attentionLevel'] == null
          ? PawAttentionLevel.undetermined
          : FirestoreMapping.enumFromJson(
              data['attentionLevel'],
              'attentionLevel',
              PawAttentionLevel.values,
            ),
      checkedAt: FirestoreMapping.utcDateTimeFromJson(
        data['checkedAt'],
        'checkedAt',
      ),
      photoUrls: _listFromFirestore(data['photoUrls'], 'photoUrls')
          .map((value) => FirestoreMapping.uriFromJson(value, 'photoUrls'))
          .toList(),
      photoStoragePaths:
          _listFromFirestore(data['photoStoragePaths'], 'photoStoragePaths')
              .map((value) => _stringFrom(value, 'photoStoragePaths'))
              .toList(),
      observations: _listFromFirestore(data['observations'], 'observations')
          .map((value) => _stringFrom(value, 'observations'))
          .toList(),
      summary: _optionalStringFrom(data['summary'], 'summary'),
      ownerNote: _optionalStringFrom(data['ownerNote'], 'ownerNote'),
      includeInVetSummary: _boolFrom(
        data['includeInVetSummary'],
        'includeInVetSummary',
      ),
      confidence: switch (data['confidence']) {
        null => 0,
        final num value => value.toDouble(),
        final other => throw FirestoreMappingException.expectedType(
            fieldName: 'confidence',
            expectedType: 'number',
            actualValue: other,
          ),
      },
      status: data['status'] == null
          ? PawCheckStatus.confirmed
          : FirestoreMapping.enumFromJson(
              data['status'],
              'status',
              PawCheckStatus.values,
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

  static List<Object?> _listFromFirestore(Object? value, String fieldName) {
    if (value == null) {
      return const [];
    }

    if (value is List) {
      return value;
    }

    throw FirestoreMappingException.expectedType(
      fieldName: fieldName,
      expectedType: 'List',
      actualValue: value,
    );
  }

  static String _stringFrom(Object? value, String fieldName) {
    if (value is String) {
      return value;
    }

    throw FirestoreMappingException.expectedType(
      fieldName: fieldName,
      expectedType: 'String',
      actualValue: value,
    );
  }

  static String? _optionalStringFrom(Object? value, String fieldName) {
    if (value == null || value is String) {
      return value as String?;
    }

    throw FirestoreMappingException.expectedType(
      fieldName: fieldName,
      expectedType: 'String?',
      actualValue: value,
    );
  }

  static bool _boolFrom(Object? value, String fieldName) {
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
