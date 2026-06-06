final class PetWeight {
  const PetWeight({
    required this.value,
    this.unit = PetWeightUnit.kilogram,
  });

  final double value;
  final PetWeightUnit unit;
}

enum PetWeightUnit {
  kilogram,
  pound,
}
