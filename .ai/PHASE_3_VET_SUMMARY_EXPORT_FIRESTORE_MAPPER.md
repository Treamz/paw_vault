# Phase 3 VetSummaryExport Firestore Mapper

## Scope

Added the Firestore mapper for `VetSummaryExport` and focused round-trip tests.
This task does not implement `VetSummaryExportRepository` Firebase behavior or
PDF export generation.

## Mapper

Created:

```text
lib/features/vet_summary_export/data/mappers/vet_summary_export_firestore_mapper.dart
```

The mapper handles:

- document ID as `VetSummaryExport.id`
- `EntityId`
- optional file URL
- optional Firebase Storage path
- required `UtcDateTime` creation timestamp

## Tests

Created:

```text
test/features/vet_summary_export/data/mappers/vet_summary_export_firestore_mapper_test.dart
```

Coverage includes:

- complete domain-to-Firestore mapping
- complete Firestore-to-domain mapping
- round-trip mapping
- defaults for missing optional fields
- invalid required field rejection
- invalid optional storage path rejection
