# Phase 3 Firebase SmartInputRepository

## Scope

Implemented Firebase `SmartInputRepository` persistence methods while keeping AI
draft creation separate from Firestore writes. Gemini/Firebase AI Logic still
only returns draft structured data through `AiRepository`.

## Implementation

Created:

```text
lib/features/smart_input/data/repositories/firebase_smart_input_repository.dart
```

Updated:

```text
lib/features/smart_input/data/datasources/firestore_smart_input_data_source.dart
lib/features/smart_input/data/datasources/flutter_fire_smart_input_data_source.dart
```

The Firebase path now supports:

- creating unsaved drafts by delegating to `AiRepository`
- watching persisted smart messages for a pet
- getting a smart message by ID
- saving only user-confirmed smart messages
- deleting smart messages
- mapping Firestore documents through `SmartMessageFirestoreMapper`

## AI Boundary

`createDraft` delegates to `AiRepository.structureUserInput(...)` and does not
write to Firestore. `saveSmartMessage` rejects messages that are not
`SmartMessageStatus.confirmed`.

## Tests

Created:

```text
test/features/smart_input/data/repositories/firebase_smart_input_repository_test.dart
```

Coverage includes:

- draft creation does not write to Firestore
- watch
- get
- confirmed save
- unconfirmed save rejection
- delete
