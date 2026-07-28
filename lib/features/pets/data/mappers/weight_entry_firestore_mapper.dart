import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/pets/domain/entities/weight_entry.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';

abstract final class WeightEntryFirestoreMapper {
  static Map<String, Object?> toFirestore(WeightEntry entry) {
    return {
      'userId': FirestoreMapping.entityIdToJson(entry.userId),
      'petId': FirestoreMapping.entityIdToJson(entry.petId),
      'value': entry.value,
      'unit': FirestoreMapping.enumToJson(entry.unit),
      'date': FirestoreMapping.dateOnlyToJson(entry.date),
      if (entry.note != null) 'note': entry.note,
      if (entry.createdAt != null)
        'createdAt': FirestoreMapping.utcDateTimeToJson(entry.createdAt!),
    };
  }

  static WeightEntry fromFirestore({
    required EntityId id,
    required Map<String, Object?> data,
  }) {
    final value = data['value'];
    if (value is! num) {
      throw FirestoreMappingException.expectedType(
        fieldName: 'value',
        expectedType: 'number',
        actualValue: value,
      );
    }

    final note = data['note'];
    if (note is! String?) {
      throw FirestoreMappingException.expectedType(
        fieldName: 'note',
        expectedType: 'String?',
        actualValue: note,
      );
    }

    return WeightEntry(
      id: id,
      userId: FirestoreMapping.entityIdFromJson(data['userId'], 'userId'),
      petId: FirestoreMapping.entityIdFromJson(data['petId'], 'petId'),
      value: value.toDouble(),
      unit: FirestoreMapping.enumFromJson(
        data['unit'],
        'unit',
        PetWeightUnit.values,
      ),
      date: FirestoreMapping.dateOnlyFromJson(data['date'], 'date'),
      note: note,
      createdAt: data['createdAt'] == null
          ? null
          : FirestoreMapping.utcDateTimeFromJson(
              data['createdAt'],
              'createdAt',
            ),
    );
  }
}
