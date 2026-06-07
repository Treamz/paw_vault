# Phase 3 PetEvent Firestore Mapper

## Scope

Added the Firestore mapper for `PetEvent` and focused round-trip tests. This
task does not implement `TimelineRepository` Firebase behavior.

## Mapper

Created:

```text
lib/features/timeline/data/mappers/pet_event_firestore_mapper.dart
```

The mapper handles:

- document ID as `PetEvent.id`
- `EntityId`
- `PetEventType`
- `PetEventSource`
- `Uri` attachments
- `UtcDateTime` timestamps
- optional next reminder date

## Tests

Created:

```text
test/features/timeline/data/mappers/pet_event_firestore_mapper_test.dart
```

Coverage includes:

- complete domain-to-Firestore mapping
- complete Firestore-to-domain mapping
- round-trip mapping
- defaults for missing optional fields
- invalid required field rejection
- invalid attachment rejection
