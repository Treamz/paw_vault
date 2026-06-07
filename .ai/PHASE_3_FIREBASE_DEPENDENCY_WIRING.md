# Phase 3 Firebase Dependency Wiring

## Scope

Updated `AppDependencies.firebaseReady(...)` to use Firebase-backed feature
repositories after mappers and repository implementations were tested.

## Firebase-Ready Repositories

`AppDependencies.firebaseReady(...)` now wires:

- `FirebasePetRepository`
- `FirebaseTimelineRepository`
- `FirebaseDocumentRepository`
- `FirebaseReminderRepository`
- `FirebaseSmartInputRepository`
- `FirebaseVetSummaryExportRepository`

Each repository receives a FlutterFire data source backed by
`FirebaseInstances.firestore`. `FirebaseSmartInputRepository` also receives the
existing `AiRepository`, preserving the boundary where AI creates drafts and the
repository persists only confirmed smart messages.

## Local-First

`AppDependencies.localFirst()` remains unchanged and still uses local/noop
repositories and noop Firebase-ready data sources.
