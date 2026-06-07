# Phase 3 Reminder Firestore Mapper

## Scope

Added the Firestore mapper for `Reminder` and focused round-trip tests. This
task does not implement `ReminderRepository` Firebase behavior.

## Mapper

Created:

```text
lib/features/reminders/data/mappers/reminder_firestore_mapper.dart
```

The mapper handles:

- document ID as `Reminder.id`
- `EntityId`
- `ReminderRepeatType`
- `UtcDateTime` timestamps
- optional description
- optional related event ID
- completed state with a default of `false` when omitted

## Tests

Created:

```text
test/features/reminders/data/mappers/reminder_firestore_mapper_test.dart
```

Coverage includes:

- complete domain-to-Firestore mapping
- complete Firestore-to-domain mapping
- round-trip mapping
- defaults for missing optional fields
- invalid required field rejection
- invalid repeat type rejection
- invalid completion flag rejection
