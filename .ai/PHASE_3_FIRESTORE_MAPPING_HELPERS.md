# Phase 3 Firestore Mapping Helpers

## Scope

Added core Firestore mapping helpers for value objects and primitive Firestore
boundaries. This task does not add feature-specific mappers or repositories.

## Helper Coverage

`FirestoreMapping` supports:

- `EntityId` to/from non-empty `String`
- `DateOnly` to/from ISO `yyyy-MM-dd` `String`
- `UtcDateTime` to/from Firestore `Timestamp`
- enum values to/from stable enum names
- `Uri` to/from non-empty `String`
- server timestamp sentinel creation

## Error Handling

Invalid mapper input throws `FirestoreMappingException` with field-oriented
messages. Feature mappers should use this helper at the data boundary and keep
invalid Firestore documents out of domain objects.

## Follow-Up

The next task should add pure tests for these helpers before feature-specific
mappers are implemented.
