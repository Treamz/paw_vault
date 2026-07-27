/// Body measurement kinds a pet can be measured by (values in centimeters).
enum PetMeasurementType {
  headCircumference,
  earDistance,
  muzzleLength,
  muzzleCircumference,
  neckCircumference,
  neckToTailLength,
  backLength,
  withersHeight,
  chestCircumference,
  bellyCircumference,
  neckToNavelLength,
  neckToPawLength,
  pawCircumference,
}

/// A single optional body measurement of a pet.
final class PetMeasurement {
  const PetMeasurement({
    required this.type,
    required this.valueCm,
  });

  final PetMeasurementType type;

  /// Measurement value in centimeters.
  final double valueCm;
}
