import 'package:paw_vault/features/pets/domain/value_objects/pet_measurement.dart';

/// Display labels for the body measurement types.
extension PetMeasurementTypeLabel on PetMeasurementType {
  String get label => switch (this) {
        PetMeasurementType.headCircumference => 'Head circumference',
        PetMeasurementType.earDistance => 'Distance between ears',
        PetMeasurementType.muzzleLength => 'Muzzle length',
        PetMeasurementType.muzzleCircumference => 'Muzzle circumference',
        PetMeasurementType.neckCircumference => 'Neck circumference',
        PetMeasurementType.neckToTailLength => 'Neck-to-tail length',
        PetMeasurementType.backLength => 'Back length',
        PetMeasurementType.withersHeight => 'Height at withers',
        PetMeasurementType.chestCircumference => 'Chest circumference',
        PetMeasurementType.bellyCircumference => 'Belly circumference',
        PetMeasurementType.neckToNavelLength => 'Neck-to-navel length',
        PetMeasurementType.neckToPawLength => 'Neck-to-paw length',
        PetMeasurementType.pawCircumference => 'Paw circumference',
      };
}
