import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/core/firebase/firestore/firestore_mapping.dart';
import 'package:paw_vault/features/pets/data/mappers/pet_firestore_mapper.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';

void main() {
  group('PetFirestoreMapper', () {
    test('maps a complete Pet to Firestore data', () {
      final pet = _pet();

      final data = PetFirestoreMapper.toFirestore(pet);

      expect(data['userId'], 'user-1');
      expect(data['name'], 'Bella');
      expect(data['species'], 'dog');
      expect(data['breed'], 'corgi');
      expect(data['birthDate'], '2020-02-03');
      expect(data['gender'], 'female');
      expect(data['weight'], {'value': 12.5, 'unit': 'kilogram'});
      expect(data['microchipNumber'], 'chip-1');
      expect(data['photoUrl'], 'https://example.com/bella.jpg');
      expect(data['allergies'], ['chicken']);
      expect(data['chronicConditions'], ['arthritis']);
      expect(data['notes'], 'Likes carrots.');
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('maps Firestore data to a complete Pet', () {
      final data = PetFirestoreMapper.toFirestore(_pet());

      final pet = PetFirestoreMapper.fromFirestore(
        id: const EntityId('pet-1'),
        data: data,
      );

      expect(pet.id, const EntityId('pet-1'));
      expect(pet.userId, const EntityId('user-1'));
      expect(pet.name, 'Bella');
      expect(pet.species, 'dog');
      expect(pet.breed, 'corgi');
      expect(pet.birthDate, const DateOnly(year: 2020, month: 2, day: 3));
      expect(pet.gender, PetGender.female);
      expect(pet.weight?.value, 12.5);
      expect(pet.weight?.unit, PetWeightUnit.kilogram);
      expect(pet.microchipNumber, 'chip-1');
      expect(pet.photoUrl, Uri.parse('https://example.com/bella.jpg'));
      expect(pet.allergies, ['chicken']);
      expect(pet.chronicConditions, ['arthritis']);
      expect(pet.notes, 'Likes carrots.');
      expect(pet.createdAt, UtcDateTime(DateTime.utc(2026, 1, 2, 3, 4)));
      expect(pet.updatedAt, UtcDateTime(DateTime.utc(2026, 1, 3, 3, 4)));
    });

    test('round-trips a complete Pet through Firestore data', () {
      final original = _pet();

      final roundTripped = PetFirestoreMapper.fromFirestore(
        id: original.id,
        data: PetFirestoreMapper.toFirestore(original),
      );

      expect(roundTripped.id, original.id);
      expect(roundTripped.userId, original.userId);
      expect(roundTripped.name, original.name);
      expect(roundTripped.species, original.species);
      expect(roundTripped.breed, original.breed);
      expect(roundTripped.birthDate, original.birthDate);
      expect(roundTripped.gender, original.gender);
      expect(roundTripped.weight?.value, original.weight?.value);
      expect(roundTripped.weight?.unit, original.weight?.unit);
      expect(roundTripped.microchipNumber, original.microchipNumber);
      expect(roundTripped.photoUrl, original.photoUrl);
      expect(roundTripped.allergies, original.allergies);
      expect(roundTripped.chronicConditions, original.chronicConditions);
      expect(roundTripped.notes, original.notes);
      expect(roundTripped.createdAt, original.createdAt);
      expect(roundTripped.updatedAt, original.updatedAt);
    });

    test('uses defaults for missing optional lists', () {
      final pet = PetFirestoreMapper.fromFirestore(
        id: const EntityId('pet-1'),
        data: const {
          'userId': 'user-1',
          'name': 'Bella',
        },
      );

      expect(pet.allergies, isEmpty);
      expect(pet.chronicConditions, isEmpty);
      expect(pet.birthDate, isNull);
      expect(pet.gender, isNull);
      expect(pet.weight, isNull);
      expect(pet.createdAt, isNull);
      expect(pet.updatedAt, isNull);
    });

    test('rejects invalid required fields', () {
      expect(
        () => PetFirestoreMapper.fromFirestore(
          id: const EntityId('pet-1'),
          data: const {
            'userId': 'user-1',
            'name': 42,
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });

    test('rejects invalid nested weight fields', () {
      expect(
        () => PetFirestoreMapper.fromFirestore(
          id: const EntityId('pet-1'),
          data: const {
            'userId': 'user-1',
            'name': 'Bella',
            'weight': {'value': 'heavy', 'unit': 'kilogram'},
          },
        ),
        throwsA(isA<FirestoreMappingException>()),
      );
    });
  });
}

Pet _pet() {
  return Pet(
    id: const EntityId('pet-1'),
    userId: const EntityId('user-1'),
    name: 'Bella',
    species: 'dog',
    breed: 'corgi',
    birthDate: const DateOnly(year: 2020, month: 2, day: 3),
    gender: PetGender.female,
    weight: const PetWeight(value: 12.5),
    microchipNumber: 'chip-1',
    photoUrl: Uri.parse('https://example.com/bella.jpg'),
    allergies: const ['chicken'],
    chronicConditions: const ['arthritis'],
    notes: 'Likes carrots.',
    createdAt: UtcDateTime(DateTime.utc(2026, 1, 2, 3, 4)),
    updatedAt: UtcDateTime(DateTime.utc(2026, 1, 3, 3, 4)),
  );
}
