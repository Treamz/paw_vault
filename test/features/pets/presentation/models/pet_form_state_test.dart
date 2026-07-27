import 'package:flutter_test/flutter_test.dart';
import 'package:paw_vault/core/domain/value_objects/date_only.dart';
import 'package:paw_vault/core/domain/value_objects/entity_id.dart';
import 'package:paw_vault/features/pets/domain/entities/pet.dart';
import 'package:paw_vault/features/pets/domain/value_objects/pet_weight.dart';
import 'package:paw_vault/features/pets/presentation/models/pet_form_state.dart';

void main() {
  group('PetFormState', () {
    test('fromPet creates form state from pet entity', () {
      final pet = Pet(
        id: const EntityId('pet-123'),
        userId: const EntityId('user-456'),
        name: 'Fluffy',
        species: 'Cat',
        breed: 'Persian',
        birthDate: const DateOnly(year: 2020, month: 5, day: 15),
        gender: PetGender.female,
        weight: const PetWeight(value: 4.5),
        microchipNumber: 'MC123456',
        photoUrl: Uri.parse('https://example.com/fluffy.jpg'),
        allergies: const ['Chicken'],
        chronicConditions: const ['Diabetes'],
        notes: 'Loves catnip',
      );

      final formState = PetFormState.fromPet(pet);

      expect(formState.name, 'Fluffy');
      expect(formState.species, 'Cat');
      expect(formState.breed, 'Persian');
      expect(
        formState.birthDate,
        const DateOnly(year: 2020, month: 5, day: 15),
      );
      expect(formState.gender, PetGender.female);
      expect(formState.weightValue, 4.5);
      expect(formState.weightUnit, PetWeightUnit.kilogram);
      expect(formState.microchipNumber, 'MC123456');
      expect(formState.photoUrl, 'https://example.com/fluffy.jpg');
      expect(formState.allergies, ['Chicken']);
      expect(formState.chronicConditions, ['Diabetes']);
      expect(formState.notes, 'Loves catnip');
    });

    test('copyWith updates specified fields only', () {
      const formState = PetFormState(name: 'Fluffy');

      final updated = formState.copyWith(
        species: 'Cat',
        weightValue: 4.5,
      );

      expect(updated.name, 'Fluffy');
      expect(updated.species, 'Cat');
      expect(updated.weightValue, 4.5);
    });

    group('validate', () {
      test('returns valid when name is provided', () {
        const formState = PetFormState(name: 'Fluffy');

        final validation = formState.validate();

        expect(validation.isValid, true);
        expect(validation.errors, isEmpty);
      });

      test('returns error when name is empty', () {
        const formState = PetFormState();

        final validation = formState.validate();

        expect(validation.isValid, false);
        expect(validation.errorFor('name'), 'Pet name is required');
      });

      test('returns error when name is whitespace only', () {
        const formState = PetFormState(name: '   ');

        final validation = formState.validate();

        expect(validation.isValid, false);
        expect(validation.errorFor('name'), 'Pet name is required');
      });

      test('returns error when name exceeds 100 characters', () {
        final longName = 'a' * 101;
        final formState = PetFormState(name: longName);

        final validation = formState.validate();

        expect(validation.isValid, false);
        expect(
          validation.errorFor('name'),
          'Pet name must be 100 characters or less',
        );
      });

      test('returns error when species exceeds 50 characters', () {
        final longSpecies = 'a' * 51;
        final formState = PetFormState(name: 'Fluffy', species: longSpecies);

        final validation = formState.validate();

        expect(validation.isValid, false);
        expect(
          validation.errorFor('species'),
          'Species must be 50 characters or less',
        );
      });

      test('returns error when breed exceeds 50 characters', () {
        final longBreed = 'a' * 51;
        final formState = PetFormState(name: 'Fluffy', breed: longBreed);

        final validation = formState.validate();

        expect(validation.isValid, false);
        expect(
          validation.errorFor('breed'),
          'Breed must be 50 characters or less',
        );
      });

      test('returns error when birth date is in the future', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final formState = PetFormState(
          name: 'Fluffy',
          birthDate: DateOnly.fromDateTime(tomorrow),
        );

        final validation = formState.validate();

        expect(validation.isValid, false);
        expect(
          validation.errorFor('birthDate'),
          'Birth date cannot be in the future',
        );
      });

      test('returns error when birth date is too old', () {
        final tooOld = DateTime(1900);
        final formState = PetFormState(
          name: 'Fluffy',
          birthDate: DateOnly.fromDateTime(tooOld),
        );

        final validation = formState.validate();

        expect(validation.isValid, false);
        expect(validation.errorFor('birthDate'), 'Birth date seems too old');
      });

      test('returns error when weight is zero or negative', () {
        const formState = PetFormState(name: 'Fluffy', weightValue: 0);

        final validation = formState.validate();

        expect(validation.isValid, false);
        expect(validation.errorFor('weight'), 'Weight must be greater than 0');
      });

      test('returns error when weight is too large', () {
        const formState = PetFormState(name: 'Fluffy', weightValue: 10001);

        final validation = formState.validate();

        expect(validation.isValid, false);
        expect(validation.errorFor('weight'), 'Weight value seems too large');
      });

      test('returns error when microchip number exceeds 50 characters', () {
        final longMicrochip = 'a' * 51;
        final formState =
            PetFormState(name: 'Fluffy', microchipNumber: longMicrochip);

        final validation = formState.validate();

        expect(validation.isValid, false);
        expect(
          validation.errorFor('microchipNumber'),
          'Microchip number must be 50 characters or less',
        );
      });

      test('does not validate photo URL (photo is picked, not typed)', () {
        const formState = PetFormState(
          name: 'Fluffy',
          photoUrl: 'users/user-1/pets/pet-1/photos/profile.jpg',
        );

        final validation = formState.validate();

        expect(validation.isValid, true);
        expect(validation.errorFor('photoUrl'), isNull);
      });

      test('accepts valid HTTP URL', () {
        const formState = PetFormState(
          name: 'Fluffy',
          photoUrl: 'http://example.com/photo.jpg',
        );

        final validation = formState.validate();

        expect(validation.isValid, true);
      });

      test('accepts valid HTTPS URL', () {
        const formState = PetFormState(
          name: 'Fluffy',
          photoUrl: 'https://example.com/photo.jpg',
        );

        final validation = formState.validate();

        expect(validation.isValid, true);
      });

      test('returns error when notes exceed 5000 characters', () {
        final longNotes = 'a' * 5001;
        final formState = PetFormState(name: 'Fluffy', notes: longNotes);

        final validation = formState.validate();

        expect(validation.isValid, false);
        expect(
          validation.errorFor('notes'),
          'Notes must be 5000 characters or less',
        );
      });

      test('allows multiple validation errors', () {
        const formState = PetFormState(
          weightValue: -5,
        );

        final validation = formState.validate();

        expect(validation.isValid, false);
        expect(validation.errors.length, 2);
        expect(validation.errorFor('name'), isNotNull);
        expect(validation.errorFor('weight'), isNotNull);
      });
    });

    group('toPet', () {
      test('converts valid form state to pet entity', () {
        const formState = PetFormState(
          name: 'Fluffy',
          species: 'Cat',
          breed: 'Persian',
          birthDate: DateOnly(year: 2020, month: 5, day: 15),
          gender: PetGender.female,
          weightValue: 4.5,
          microchipNumber: 'MC123456',
          photoUrl: 'https://example.com/fluffy.jpg',
          allergies: ['Chicken'],
          chronicConditions: ['Diabetes'],
          notes: 'Loves catnip',
        );

        final pet = formState.toPet(
          id: const EntityId('pet-123'),
          userId: const EntityId('user-456'),
        );

        expect(pet.id, const EntityId('pet-123'));
        expect(pet.userId, const EntityId('user-456'));
        expect(pet.name, 'Fluffy');
        expect(pet.species, 'Cat');
        expect(pet.breed, 'Persian');
        expect(pet.birthDate, const DateOnly(year: 2020, month: 5, day: 15));
        expect(pet.gender, PetGender.female);
        expect(pet.weight?.value, 4.5);
        expect(pet.weight?.unit, PetWeightUnit.kilogram);
        expect(pet.microchipNumber, 'MC123456');
        expect(pet.photoUrl, Uri.parse('https://example.com/fluffy.jpg'));
        expect(pet.allergies, ['Chicken']);
        expect(pet.chronicConditions, ['Diabetes']);
        expect(pet.notes, 'Loves catnip');
      });

      test('trims whitespace from string fields', () {
        const formState = PetFormState(
          name: '  Fluffy  ',
          species: '  Cat  ',
          breed: '  Persian  ',
          microchipNumber: '  MC123  ',
          notes: '  Some notes  ',
        );

        final pet = formState.toPet(
          id: const EntityId('pet-123'),
          userId: const EntityId('user-456'),
        );

        expect(pet.name, 'Fluffy');
        expect(pet.species, 'Cat');
        expect(pet.breed, 'Persian');
        expect(pet.microchipNumber, 'MC123');
        expect(pet.notes, 'Some notes');
      });

      test('converts empty optional strings to null', () {
        const formState = PetFormState(
          name: 'Fluffy',
          species: '',
          breed: '   ',
          microchipNumber: '',
          notes: '',
        );

        final pet = formState.toPet(
          id: const EntityId('pet-123'),
          userId: const EntityId('user-456'),
        );

        expect(pet.species, null);
        expect(pet.breed, null);
        expect(pet.microchipNumber, null);
        expect(pet.notes, null);
      });

      test('throws PetFormValidationException when form is invalid', () {
        const formState = PetFormState();

        expect(
          () => formState.toPet(
            id: const EntityId('pet-123'),
            userId: const EntityId('user-456'),
          ),
          throwsA(isA<PetFormValidationException>()),
        );
      });

      test('includes timestamps when provided', () {
        const formState = PetFormState(name: 'Fluffy');
        final now = DateTime.now();

        final pet = formState.toPet(
          id: const EntityId('pet-123'),
          userId: const EntityId('user-456'),
          createdAt: now,
          updatedAt: now,
        );

        expect(pet.createdAt, isNotNull);
        expect(pet.updatedAt, isNotNull);
      });
    });
  });
}
