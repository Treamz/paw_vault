# Phase 3 PetDocument Firestore Mapper

## Scope

Added the Firestore mapper for `PetDocument` and focused round-trip tests. This
task does not implement `DocumentRepository` Firebase behavior.

## Mapper

Created:

```text
lib/features/documents/data/mappers/pet_document_firestore_mapper.dart
```

The mapper handles:

- document ID as `PetDocument.id`
- `EntityId`
- `PetDocumentType`
- `Uri` file URL
- storage path
- extracted text/data
- `DateOnly` issue/expiry dates
- linked event ID
- `UtcDateTime` timestamps

## Tests

Created:

```text
test/features/documents/data/mappers/pet_document_firestore_mapper_test.dart
```

Coverage includes:

- complete domain-to-Firestore mapping
- complete Firestore-to-domain mapping
- round-trip mapping
- defaults for missing optional fields
- invalid required field rejection
- invalid extracted data rejection
