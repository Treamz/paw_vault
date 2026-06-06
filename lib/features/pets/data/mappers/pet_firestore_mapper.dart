import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';

abstract final class PetFirestoreMapper {
  static Map<String, Object?> toFirestore(Pet pet) {
    return {
      'userId': FirestoreMapping.entityIdToJson(pet.userId),
      'name': pet.name,
      if (pet.species != null) 'species': pet.species,
      if (pet.breed != null) 'breed': pet.breed,
      if (pet.birthDate != null)
        'birthDate': FirestoreMapping.dateOnlyToJson(pet.birthDate!),
      if (pet.gender != null)
        'gender': FirestoreMapping.enumToJson(pet.gender!),
      if (pet.weight != null) 'weight': _weightToFirestore(pet.weight!),
      if (pet.microchipNumber != null) 'microchipNumber': pet.microchipNumber,
      if (pet.photoUrl != null)
        'photoUrl': FirestoreMapping.uriToJson(pet.photoUrl!),
      'allergies': pet.allergies,
      'chronicConditions': pet.chronicConditions,
      if (pet.notes != null) 'notes': pet.notes,
      if (pet.createdAt != null)
        'createdAt': FirestoreMapping.utcDateTimeToJson(pet.createdAt!),
      if (pet.updatedAt != null)
        'updatedAt': FirestoreMapping.utcDateTimeToJson(pet.updatedAt!),
    };
  }

  static Pet fromFirestore({
    required EntityId id,
    required Map<String, Object?> data,
  }) {
    return Pet(
      id: id,
      userId: FirestoreMapping.entityIdFromJson(data['userId'], 'userId'),
      name: _stringFromFirestore(data['name'], 'name'),
      species: _optionalStringFromFirestore(data['species'], 'species'),
      breed: _optionalStringFromFirestore(data['breed'], 'breed'),
      birthDate: data['birthDate'] == null
          ? null
          : FirestoreMapping.dateOnlyFromJson(data['birthDate'], 'birthDate'),
      gender: data['gender'] == null
          ? null
          : FirestoreMapping.enumFromJson(
              data['gender'],
              'gender',
              PetGender.values,
            ),
      weight: data['weight'] == null
          ? null
          : _weightFromFirestore(data['weight'], 'weight'),
      microchipNumber: _optionalStringFromFirestore(
        data['microchipNumber'],
        'microchipNumber',
      ),
      photoUrl: data['photoUrl'] == null
          ? null
          : FirestoreMapping.uriFromJson(data['photoUrl'], 'photoUrl'),
      allergies: _stringListFromFirestore(data['allergies'], 'allergies'),
      chronicConditions: _stringListFromFirestore(
        data['chronicConditions'],
        'chronicConditions',
      ),
      notes: _optionalStringFromFirestore(data['notes'], 'notes'),
      createdAt: data['createdAt'] == null
          ? null
          : FirestoreMapping.utcDateTimeFromJson(
              data['createdAt'], 'createdAt'),
      updatedAt: data['updatedAt'] == null
          ? null
          : FirestoreMapping.utcDateTimeFromJson(
              data['updatedAt'], 'updatedAt'),
    );
  }

  static Map<String, Object?> _weightToFirestore(PetWeight weight) {
    return {
      'value': weight.value,
      'unit': FirestoreMapping.enumToJson(weight.unit),
    };
  }

  static PetWeight _weightFromFirestore(Object? value, String fieldName) {
    if (value is! Map) {
      throw FirestoreMappingException.expectedType(
        fieldName: fieldName,
        expectedType: 'Map',
        actualValue: value,
      );
    }

    final weightValue = value['value'];
    if (weightValue is! num) {
      throw FirestoreMappingException.expectedType(
        fieldName: '$fieldName.value',
        expectedType: 'number',
        actualValue: weightValue,
      );
    }

    return PetWeight(
      value: weightValue.toDouble(),
      unit: FirestoreMapping.enumFromJson(
        value['unit'],
        '$fieldName.unit',
        PetWeightUnit.values,
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

  static List<String> _stringListFromFirestore(
    Object? value,
    String fieldName,
  ) {
    if (value == null) {
      return const [];
    }

    if (value is List && value.every((item) => item is String)) {
      return value.cast<String>();
    }

    throw FirestoreMappingException.expectedType(
      fieldName: fieldName,
      expectedType: 'List<String>',
      actualValue: value,
    );
  }
}
