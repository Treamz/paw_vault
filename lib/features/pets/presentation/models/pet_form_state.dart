import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/core/domain/value_objects/utc_date_time.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';

class PetFormState {
  const PetFormState({
    this.name = '',
    this.species,
    this.breed,
    this.birthDate,
    this.gender,
    this.weightValue,
    this.weightUnit = PetWeightUnit.kilogram,
    this.microchipNumber,
    this.photoUrl,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.notes,
  });

  factory PetFormState.fromPet(Pet pet) {
    return PetFormState(
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      birthDate: pet.birthDate,
      gender: pet.gender,
      weightValue: pet.weight?.value,
      weightUnit: pet.weight?.unit ?? PetWeightUnit.kilogram,
      microchipNumber: pet.microchipNumber,
      photoUrl: pet.photoUrl?.toString(),
      allergies: List.from(pet.allergies),
      chronicConditions: List.from(pet.chronicConditions),
      notes: pet.notes,
    );
  }

  final String name;
  final String? species;
  final String? breed;
  final DateOnly? birthDate;
  final PetGender? gender;
  final double? weightValue;
  final PetWeightUnit weightUnit;
  final String? microchipNumber;
  final String? photoUrl;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String? notes;

  PetFormState copyWith({
    String? name,
    String? species,
    String? breed,
    DateOnly? birthDate,
    PetGender? gender,
    double? weightValue,
    PetWeightUnit? weightUnit,
    String? microchipNumber,
    String? photoUrl,
    List<String>? allergies,
    List<String>? chronicConditions,
    String? notes,
  }) {
    return PetFormState(
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      weightValue: weightValue ?? this.weightValue,
      weightUnit: weightUnit ?? this.weightUnit,
      microchipNumber: microchipNumber ?? this.microchipNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      notes: notes ?? this.notes,
    );
  }

  PetFormValidation validate() {
    final errors = <String, String>{};

    if (name.trim().isEmpty) {
      errors['name'] = 'Pet name is required';
    } else if (name.trim().length > 100) {
      errors['name'] = 'Pet name must be 100 characters or less';
    }

    if (species != null && species!.trim().length > 50) {
      errors['species'] = 'Species must be 50 characters or less';
    }

    if (breed != null && breed!.trim().length > 50) {
      errors['breed'] = 'Breed must be 50 characters or less';
    }

    if (birthDate != null) {
      final now = DateTime.now();
      final birthDateTime = birthDate!.toUtcDateTime();
      if (birthDateTime.isAfter(now)) {
        errors['birthDate'] = 'Birth date cannot be in the future';
      }
      final maxAge = DateTime(now.year - 100, now.month, now.day);
      if (birthDateTime.isBefore(maxAge)) {
        errors['birthDate'] = 'Birth date seems too old';
      }
    }

    if (weightValue != null && weightValue! <= 0) {
      errors['weight'] = 'Weight must be greater than 0';
    }
    if (weightValue != null && weightValue! > 10000) {
      errors['weight'] = 'Weight value seems too large';
    }

    if (microchipNumber != null &&
        microchipNumber!.trim().isNotEmpty &&
        microchipNumber!.trim().length > 50) {
      errors['microchipNumber'] =
          'Microchip number must be 50 characters or less';
    }

    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      final uri = Uri.tryParse(photoUrl!.trim());
      if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        errors['photoUrl'] = 'Photo URL must be a valid HTTP or HTTPS URL';
      }
    }

    if (notes != null && notes!.trim().length > 5000) {
      errors['notes'] = 'Notes must be 5000 characters or less';
    }

    return PetFormValidation(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  Pet toPet({
    required EntityId id,
    required EntityId userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final validation = validate();
    if (!validation.isValid) {
      throw PetFormValidationException(validation.errors);
    }

    final trimmedName = name.trim();
    final trimmedSpecies = species?.trim();
    final trimmedBreed = breed?.trim();
    final trimmedMicrochip = microchipNumber?.trim();
    final trimmedPhotoUrl = photoUrl?.trim();
    final trimmedNotes = notes?.trim();

    return Pet(
      id: id,
      userId: userId,
      name: trimmedName,
      species: trimmedSpecies != null && trimmedSpecies.isNotEmpty
          ? trimmedSpecies
          : null,
      breed:
          trimmedBreed != null && trimmedBreed.isNotEmpty ? trimmedBreed : null,
      birthDate: birthDate,
      gender: gender,
      weight: weightValue != null
          ? PetWeight(value: weightValue!, unit: weightUnit)
          : null,
      microchipNumber: trimmedMicrochip != null && trimmedMicrochip.isNotEmpty
          ? trimmedMicrochip
          : null,
      photoUrl: trimmedPhotoUrl != null && trimmedPhotoUrl.isNotEmpty
          ? Uri.parse(trimmedPhotoUrl)
          : null,
      allergies: allergies,
      chronicConditions: chronicConditions,
      notes:
          trimmedNotes != null && trimmedNotes.isNotEmpty ? trimmedNotes : null,
      createdAt: createdAt != null ? UtcDateTime(createdAt) : null,
      updatedAt: updatedAt != null ? UtcDateTime(updatedAt) : null,
    );
  }
}

class PetFormValidation {
  const PetFormValidation({
    required this.isValid,
    required this.errors,
  });

  final bool isValid;
  final Map<String, String> errors;

  String? errorFor(String field) => errors[field];
}

class PetFormValidationException implements Exception {
  const PetFormValidationException(this.errors);

  final Map<String, String> errors;

  @override
  String toString() {
    return 'PetFormValidationException: ${errors.entries.map((e) => '${e.key}: ${e.value}').join(', ')}';
  }
}
