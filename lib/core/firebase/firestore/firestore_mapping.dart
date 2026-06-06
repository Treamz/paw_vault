import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';

abstract final class FirestoreMapping {
  static String entityIdToJson(EntityId value) => value.value;

  static EntityId entityIdFromJson(Object? value, String fieldName) {
    if (value is String && value.trim().isNotEmpty) {
      return EntityId(value);
    }

    throw FirestoreMappingException.expectedType(
      fieldName: fieldName,
      expectedType: 'non-empty String',
      actualValue: value,
    );
  }

  static String dateOnlyToJson(DateOnly value) => value.toString();

  static DateOnly dateOnlyFromJson(Object? value, String fieldName) {
    if (value is! String) {
      throw FirestoreMappingException.expectedType(
        fieldName: fieldName,
        expectedType: 'ISO date String',
        actualValue: value,
      );
    }

    final parts = value.split('-');
    if (parts.length != 3) {
      throw FirestoreMappingException.invalidValue(
        fieldName: fieldName,
        message: 'Expected yyyy-MM-dd.',
        actualValue: value,
      );
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      throw FirestoreMappingException.invalidValue(
        fieldName: fieldName,
        message: 'Expected numeric yyyy-MM-dd parts.',
        actualValue: value,
      );
    }

    return DateOnly(year: year, month: month, day: day);
  }

  static Timestamp utcDateTimeToJson(UtcDateTime value) {
    return Timestamp.fromDate(value.value);
  }

  static UtcDateTime utcDateTimeFromJson(Object? value, String fieldName) {
    if (value is Timestamp) {
      return UtcDateTime(value.toDate());
    }

    if (value is DateTime) {
      return UtcDateTime(value);
    }

    throw FirestoreMappingException.expectedType(
      fieldName: fieldName,
      expectedType: 'Timestamp',
      actualValue: value,
    );
  }

  static String enumToJson(Enum value) => value.name;

  static T enumFromJson<T extends Enum>(
    Object? value,
    String fieldName,
    Iterable<T> values,
  ) {
    if (value is String) {
      for (final enumValue in values) {
        if (enumValue.name == value) {
          return enumValue;
        }
      }
    }

    throw FirestoreMappingException.invalidValue(
      fieldName: fieldName,
      message:
          'Expected one of: ${values.map((value) => value.name).join(', ')}.',
      actualValue: value,
    );
  }

  static String uriToJson(Uri value) => value.toString();

  static Uri uriFromJson(Object? value, String fieldName) {
    if (value is String && value.trim().isNotEmpty) {
      return Uri.parse(value);
    }

    throw FirestoreMappingException.expectedType(
      fieldName: fieldName,
      expectedType: 'non-empty URI String',
      actualValue: value,
    );
  }

  static FieldValue serverTimestamp() => FieldValue.serverTimestamp();
}

class FirestoreMappingException implements Exception {
  const FirestoreMappingException(this.message);

  factory FirestoreMappingException.expectedType({
    required String fieldName,
    required String expectedType,
    required Object? actualValue,
  }) {
    return FirestoreMappingException(
      'Expected $fieldName to be $expectedType, got ${actualValue.runtimeType}.',
    );
  }

  factory FirestoreMappingException.invalidValue({
    required String fieldName,
    required String message,
    required Object? actualValue,
  }) {
    return FirestoreMappingException(
      'Invalid $fieldName value "$actualValue". $message',
    );
  }

  final String message;

  @override
  String toString() => 'FirestoreMappingException: $message';
}
