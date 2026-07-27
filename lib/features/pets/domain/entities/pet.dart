import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_measurement.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';

enum PetGender {
  female,
  male,
  unknown,
}

class Pet {
  const Pet({
    required this.id,
    required this.userId,
    required this.name,
    this.species,
    this.breed,
    this.birthDate,
    this.gender,
    this.weight,
    this.measurements = const [],
    this.microchipNumber,
    this.photoUrl,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final EntityId id;
  final EntityId userId;
  final String name;
  final String? species;
  final String? breed;
  final DateOnly? birthDate;
  final PetGender? gender;
  final PetWeight? weight;

  /// Optional body measurements (head/neck/chest circumference, lengths…).
  final List<PetMeasurement> measurements;
  final String? microchipNumber;
  final Uri? photoUrl;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String? notes;
  final UtcDateTime? createdAt;
  final UtcDateTime? updatedAt;
}
