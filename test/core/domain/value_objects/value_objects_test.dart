import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';

void main() {
  group('EntityId', () {
    test('compares by wrapped value', () {
      expect(const EntityId('pet-1'), equals(const EntityId('pet-1')));
      expect(const EntityId('pet-1'), isNot(equals(const EntityId('pet-2'))));
    });

    test('treats whitespace-only values as empty', () {
      expect(const EntityId('   ').isEmpty, isTrue);
      expect(const EntityId('pet-1').isEmpty, isFalse);
    });

    test('returns the wrapped value as a string', () {
      expect(const EntityId('user-1').toString(), 'user-1');
    });
  });

  group('DateOnly', () {
    test('formats as an ISO date string', () {
      expect(
        const DateOnly(year: 2026, month: 6, day: 6).toString(),
        '2026-06-06',
      );
    });

    test('converts to a UTC midnight DateTime', () {
      expect(
        const DateOnly(year: 2026, month: 6, day: 6).toUtcDateTime(),
        DateTime.utc(2026, 6, 6),
      );
    });

    test('compares by calendar date', () {
      final earlier = const DateOnly(year: 2026, month: 6, day: 5);
      final later = const DateOnly(year: 2026, month: 6, day: 6);

      expect(earlier.compareTo(later), isNegative);
      expect(later.compareTo(earlier), isPositive);
      expect(later.compareTo(later), isZero);
    });

    test('creates a date-only value from a DateTime', () {
      final value = DateOnly.fromDateTime(DateTime(2026, 6, 6, 23, 59));

      expect(value, const DateOnly(year: 2026, month: 6, day: 6));
    });
  });

  group('UtcDateTime', () {
    test('normalizes values to UTC', () {
      final value = UtcDateTime(
        DateTime.parse('2026-06-06T12:30:00+02:00'),
      );

      expect(value.value.isUtc, isTrue);
      expect(value.value, DateTime.utc(2026, 6, 6, 10, 30));
    });

    test('compares by instant', () {
      final earlier = UtcDateTime(DateTime.utc(2026, 6, 6, 10));
      final later = UtcDateTime(DateTime.utc(2026, 6, 6, 11));

      expect(earlier.compareTo(later), isNegative);
      expect(later.compareTo(earlier), isPositive);
      expect(later.compareTo(later), isZero);
    });

    test('returns ISO string output', () {
      final value = UtcDateTime(DateTime.utc(2026, 6, 6, 10, 30));

      expect(value.toString(), '2026-06-06T10:30:00.000Z');
    });
  });

  group('PetWeight', () {
    test('defaults to kilograms', () {
      const weight = PetWeight(value: 12.5);

      expect(weight.value, 12.5);
      expect(weight.unit, PetWeightUnit.kilogram);
    });

    test('can represent pounds', () {
      const weight = PetWeight(value: 22, unit: PetWeightUnit.pound);

      expect(weight.value, 22);
      expect(weight.unit, PetWeightUnit.pound);
    });
  });
}
