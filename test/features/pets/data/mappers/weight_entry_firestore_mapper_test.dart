import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/pets/data/mappers/weight_entry_firestore_mapper.dart';
import 'package:paw_vault/features/pets/domain/entities/weight_entry.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';

void main() {
  group('WeightEntryFirestoreMapper', () {
    test('round-trips a complete entry', () {
      final original = WeightEntry(
        id: const EntityId('entry-1'),
        userId: const EntityId('user-1'),
        petId: const EntityId('pet-1'),
        value: 6.5,
        date: const DateOnly(year: 2026, month: 7, day: 28),
        note: 'after diet',
        createdAt: UtcDateTime(DateTime.utc(2026, 7, 28, 10)),
      );

      final roundTripped = WeightEntryFirestoreMapper.fromFirestore(
        id: original.id,
        data: WeightEntryFirestoreMapper.toFirestore(original),
      );

      expect(roundTripped.id, original.id);
      expect(roundTripped.userId, original.userId);
      expect(roundTripped.petId, original.petId);
      expect(roundTripped.value, original.value);
      expect(roundTripped.unit, original.unit);
      expect(roundTripped.date, original.date);
      expect(roundTripped.note, original.note);
      expect(roundTripped.createdAt, original.createdAt);
    });

    test('defaults optional fields when missing', () {
      final entry = WeightEntryFirestoreMapper.fromFirestore(
        id: const EntityId('entry-1'),
        data: const {
          'userId': 'user-1',
          'petId': 'pet-1',
          'value': 12,
          'unit': 'pound',
          'date': '2026-01-05',
        },
      );

      expect(entry.value, 12);
      expect(entry.unit, PetWeightUnit.pound);
      expect(entry.note, isNull);
      expect(entry.createdAt, isNull);
    });
  });

  group('WeightEntry.valueIn', () {
    const entry = WeightEntry(
      id: EntityId('e'),
      userId: EntityId('u'),
      petId: EntityId('p'),
      value: 10,
      date: DateOnly(year: 2026, month: 1, day: 1),
    );

    test('converts kilograms to pounds', () {
      expect(entry.valueIn(PetWeightUnit.pound), closeTo(22.05, 0.01));
    });

    test('returns the raw value for the same unit', () {
      expect(entry.valueIn(PetWeightUnit.kilogram), 10);
    });
  });
}
