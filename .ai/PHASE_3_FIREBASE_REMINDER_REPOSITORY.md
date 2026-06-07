# Phase 3 Firebase ReminderRepository

## Scope

Implemented the Firebase `ReminderRepository` path using the existing
repository contract and `ReminderFirestoreMapper`. This task does not switch
`AppDependencies.firebaseReady(...)` to use Firebase repositories yet.

## Implementation

Created:

```text
lib/features/reminders/data/repositories/firebase_reminder_repository.dart
```

Updated:

```text
lib/features/reminders/data/datasources/firestore_reminder_data_source.dart
lib/features/reminders/data/datasources/flutter_fire_reminder_data_source.dart
```

The Firebase path now supports:

- watching reminders for a pet
- getting a reminder by ID
- saving a reminder with server-managed `createdAt` and `updatedAt`
- completing a reminder with a targeted `isCompleted` update
- deleting a reminder
- mapping Firestore documents through `ReminderFirestoreMapper`

## Tests

Created:

```text
test/features/reminders/data/repositories/firebase_reminder_repository_test.dart
```

Coverage includes repository delegation for:

- watch
- get
- save
- complete
- delete
