# Phase 3 Repository-Level Tests

## Scope

Reviewed repository-level test coverage and added the remaining useful fake
data-source tests for core repository wrappers. Feature Firebase repositories
already had delegation tests from their implementation tasks.

## Added Coverage

Created:

```text
test/core/auth/data/repositories/firebase_ready_auth_repository_test.dart
test/core/storage/data/repositories/firebase_ready_storage_repository_test.dart
test/features/smart_input/data/repositories/firebase_ready_ai_repository_test.dart
```

Coverage includes:

- auth repository delegation for watch/current/sign-in/sign-out
- storage repository delegation for upload/delete
- AI repository delegation for user input and document text structuring

## Existing Coverage Confirmed

Existing repository-level tests cover:

- `FirebasePetRepository`
- `FirebaseTimelineRepository`
- `FirebaseDocumentRepository`
- `FirebaseReminderRepository`
- `FirebaseSmartInputRepository`
- `FirebaseVetSummaryExportRepository`
