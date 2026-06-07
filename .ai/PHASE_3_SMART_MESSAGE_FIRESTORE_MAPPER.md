# Phase 3 SmartMessage Firestore Mapper

## Scope

Added the Firestore mapper for `SmartMessage` and focused round-trip tests. This
task does not implement `SmartInputRepository` Firebase behavior or any Gemini
write path.

## Mapper

Created:

```text
lib/features/smart_input/data/mappers/smart_message_firestore_mapper.dart
```

The mapper handles:

- document ID as `SmartMessage.id`
- `EntityId`
- `SmartMessageIntent`
- `SmartMessageStatus`
- `SmartSuggestedActionType`
- extracted draft data maps
- suggested action payload maps
- numeric confidence values
- optional `UtcDateTime` creation timestamp

## Tests

Created:

```text
test/features/smart_input/data/mappers/smart_message_firestore_mapper_test.dart
```

Coverage includes:

- complete domain-to-Firestore mapping
- complete Firestore-to-domain mapping
- round-trip mapping
- defaults for missing optional map/list/timestamp fields
- invalid required field rejection
- invalid extracted data rejection
- invalid suggested action rejection
