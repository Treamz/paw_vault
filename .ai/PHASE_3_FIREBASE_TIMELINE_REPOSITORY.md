# Phase 3 Firebase TimelineRepository

## Scope

Implemented the Firebase `TimelineRepository` path using the existing
repository contract and `PetEventFirestoreMapper`. This task does not switch
`AppDependencies.firebaseReady(...)` to use Firebase repositories yet.

## Implementation

Created:

```text
lib/features/timeline/data/repositories/firebase_timeline_repository.dart
```

Updated:

```text
lib/features/timeline/data/datasources/firestore_timeline_data_source.dart
lib/features/timeline/data/datasources/flutter_fire_timeline_data_source.dart
```

The Firebase path now supports:

- watching timeline events for a pet
- getting an event by ID
- saving an event with server-managed `createdAt` and `updatedAt`
- deleting an event
- mapping Firestore documents through `PetEventFirestoreMapper`

## Tests

Created:

```text
test/features/timeline/data/repositories/firebase_timeline_repository_test.dart
```

Coverage includes repository delegation for:

- watch
- get
- save
- delete
