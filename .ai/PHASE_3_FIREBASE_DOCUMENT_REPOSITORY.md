# Phase 3 Firebase DocumentRepository

## Scope

Implemented the Firebase `DocumentRepository` path using the existing
repository contract and `PetDocumentFirestoreMapper`. This task does not switch
`AppDependencies.firebaseReady(...)` to use Firebase repositories yet.

## Implementation

Created:

```text
lib/features/documents/data/repositories/firebase_document_repository.dart
```

Updated:

```text
lib/features/documents/data/datasources/firestore_document_data_source.dart
lib/features/documents/data/datasources/flutter_fire_document_data_source.dart
```

The Firebase path now supports:

- watching documents for a pet
- getting a document by ID
- saving a document with server-managed `createdAt` and `updatedAt`
- deleting a document
- mapping Firestore documents through `PetDocumentFirestoreMapper`

## Tests

Created:

```text
test/features/documents/data/repositories/firebase_document_repository_test.dart
```

Coverage includes repository delegation for:

- watch
- get
- save
- delete
