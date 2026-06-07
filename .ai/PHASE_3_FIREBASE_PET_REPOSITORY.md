# Phase 3 Firebase PetRepository

## Scope

Implemented the Firebase `PetRepository` path using the existing repository
contract and `PetFirestoreMapper`. This task does not switch
`AppDependencies.firebaseReady(...)` to use Firebase repositories yet; that is a
later Phase 3 task after the rest of the repositories are implemented.

## Implementation

Created:

```text
lib/features/pets/data/repositories/firebase_pet_repository.dart
```

Updated:

```text
lib/features/pets/data/datasources/firestore_pet_data_source.dart
lib/features/pets/data/datasources/flutter_fire_pet_data_source.dart
```

The Firebase path now supports:

- watching pets for a user
- getting a pet by ID
- saving a pet with server-managed `createdAt` and `updatedAt`
- deleting a pet
- mapping Firestore documents through `PetFirestoreMapper`

## Tests

Created:

```text
test/features/pets/data/repositories/firebase_pet_repository_test.dart
```

Coverage includes repository delegation for:

- watch
- get
- save
- delete
