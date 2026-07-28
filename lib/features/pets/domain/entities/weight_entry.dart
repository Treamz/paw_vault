import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';

/// A single weight measurement in a pet's history.
class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.userId,
    required this.petId,
    required this.value,
    required this.date,
    this.unit = PetWeightUnit.kilogram,
    this.note,
    this.createdAt,
  });

  final EntityId id;
  final EntityId userId;
  final EntityId petId;
  final double value;
  final PetWeightUnit unit;
  final DateOnly date;
  final String? note;
  final UtcDateTime? createdAt;

  static const _poundsPerKilogram = 2.20462;

  /// The measurement expressed in [target] units.
  double valueIn(PetWeightUnit target) {
    if (unit == target) {
      return value;
    }
    return switch (target) {
      PetWeightUnit.pound => value * _poundsPerKilogram,
      PetWeightUnit.kilogram => value / _poundsPerKilogram,
    };
  }
}
