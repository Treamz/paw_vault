# Phase 3 Pet Firestore Mapper

## Scope

Added the Firestore mapper for `Pet` and focused round-trip tests. This task
does not implement `PetRepository` Firebase behavior.

## Mapper

Created:

```text
lib/features/pets/data/mappers/pet_firestore_mapper.dart
```

The mapper handles:

- document ID as `Pet.id`
- `EntityId`
- `DateOnly`
- `PetGender`
- `PetWeight`
- `Uri`
- string lists
- `UtcDateTime` timestamps

## Tests

Created:

```text
test/features/pets/data/mappers/pet_firestore_mapper_test.dart
```

Coverage includes:

- complete domain-to-Firestore mapping
- complete Firestore-to-domain mapping
- round-trip mapping
- defaults for missing optional lists
- invalid required field rejection
- invalid nested weight rejection
