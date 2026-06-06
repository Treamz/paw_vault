# Phase 2 Repository Contracts

## Scope

Expanded domain repository interfaces with read/write method contracts only.
No Firebase behavior, Firestore mapping, storage upload flow, or feature
workflow was implemented in this task.

## Contracts Added

### PetRepository

- `watchPets`
- `getPet`
- `savePet`
- `deletePet`

### TimelineRepository

- `watchEvents`
- `getEvent`
- `saveEvent`
- `deleteEvent`

### DocumentRepository

- `watchDocuments`
- `getDocument`
- `saveDocument`
- `deleteDocument`

### ReminderRepository

- `watchReminders`
- `getReminder`
- `saveReminder`
- `completeReminder`
- `deleteReminder`

### SmartInputRepository

- `createDraft`
- `watchSmartMessages`
- `getSmartMessage`
- `saveSmartMessage`
- `deleteSmartMessage`

### VetSummaryExportRepository

- `watchExports`
- `getExport`
- `saveExport`
- `deleteExport`

## Placeholder Implementations

Local/no-op repositories now satisfy the contracts with empty streams, `null`
reads, and no-op writes. This keeps the app placeholder-first while making the
future Firebase repository boundary explicit.

## Follow-Up

- Add Firestore mapping plan for all entities and value objects.
- Implement Firebase repositories in Phase 3 after mapping contracts are clear.
