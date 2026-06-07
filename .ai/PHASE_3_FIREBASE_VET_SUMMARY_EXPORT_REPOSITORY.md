# Phase 3 Firebase VetSummaryExportRepository

## Scope

Implemented the Firebase `VetSummaryExportRepository` path using the existing
repository contract and `VetSummaryExportFirestoreMapper`. This task does not
switch `AppDependencies.firebaseReady(...)` to use Firebase repositories yet.

## Implementation

Created:

```text
lib/features/vet_summary_export/data/datasources/firestore_vet_summary_export_data_source.dart
lib/features/vet_summary_export/data/datasources/flutter_fire_vet_summary_export_data_source.dart
lib/features/vet_summary_export/data/repositories/firebase_vet_summary_export_repository.dart
```

Updated:

```text
lib/core/firebase/firestore/firestore_paths.dart
```

The Firebase path now supports:

- watching vet summary exports for a pet
- getting an export by ID
- saving an export with server-managed `createdAt`
- deleting an export
- mapping Firestore documents through `VetSummaryExportFirestoreMapper`

## Tests

Created:

```text
test/features/vet_summary_export/data/repositories/firebase_vet_summary_export_repository_test.dart
```

Coverage includes repository delegation for:

- watch
- get
- save
- delete
