# Phase 2 Firestore Mapping Plan

## Scope

This plan defines how PawVault domain entities and value objects should map to
Firestore documents. It is a contract for future mapper and repository
implementation. This task does not implement Firebase repositories or mapper
code.

## Collection Layout

Use the nested MVP structure from the spec:

```text
users/{userId}
  pets/{petId}
    events/{eventId}
    documents/{documentId}
    reminders/{reminderId}
    smartMessages/{messageId}
    vetSummaryExports/{exportId}
```

`users/{userId}` should exist for ownership metadata, but feature data belongs
under the nested pet path.

## General Mapping Rules

- Domain `EntityId` maps to Firestore document IDs or string reference fields.
- Domain `Uri` maps to a string URL field.
- Domain `DateOnly` maps to an ISO `yyyy-MM-dd` string.
- Domain `UtcDateTime` maps to Firestore `Timestamp`.
- Domain enums map to stable lower camel case strings matching enum names.
- Domain `Map<String, Object?>` maps to Firestore map fields unchanged, after
  validating that nested values are Firestore-compatible.
- `createdAt` and `updatedAt` should be written with server timestamps in
  Firebase repository implementations.
- Reads should convert missing optional fields to `null` or documented defaults.
- Reads should reject documents missing required fields at the mapper boundary.
- Mappers must not live in widgets or Cubits.

## Timestamp Rules

Use Firestore `Timestamp` for:

- `createdAt`
- `updatedAt`
- event `date`
- event `nextReminderDate`
- reminder `dateTime`
- vet summary export `createdAt`

Use `FieldValue.serverTimestamp()` for writes to:

- `createdAt` when creating a document.
- `updatedAt` when creating or updating a document.

Use explicit client-provided timestamps for user-entered event dates and
reminder dates. Convert those into `UtcDateTime` in domain and Firestore
`Timestamp` in data mapping.

## Date-Only Rules

Use ISO date strings for `DateOnly`:

```text
2026-06-06
```

This applies to:

- pet `birthDate`
- document `issueDate`
- document `expiryDate`

Do not store date-only values as timestamps unless the product later needs
timezone-aware interpretation.

## Pet Document

Path:

```text
users/{userId}/pets/{petId}
```

Fields:

- `userId`: string
- `name`: string
- `species`: string?
- `breed`: string?
- `birthDate`: string?
- `gender`: string?
- `weight`: map?
  - `value`: number
  - `unit`: string
- `microchipNumber`: string?
- `photoUrl`: string?
- `allergies`: list<string>
- `chronicConditions`: list<string>
- `notes`: string?
- `createdAt`: Timestamp
- `updatedAt`: Timestamp

The Firestore document ID is the pet ID.

## PetEvent Document

Path:

```text
users/{userId}/pets/{petId}/events/{eventId}
```

Fields:

- `userId`: string
- `petId`: string
- `type`: string
- `title`: string
- `description`: string?
- `date`: Timestamp
- `nextReminderDate`: Timestamp?
- `attachments`: list<string>
- `source`: string
- `createdAt`: Timestamp
- `updatedAt`: Timestamp

The Firestore document ID is the event ID.

## PetDocument Document

Path:

```text
users/{userId}/pets/{petId}/documents/{documentId}
```

Fields:

- `userId`: string
- `petId`: string
- `title`: string
- `type`: string
- `fileUrl`: string?
- `storagePath`: string
- `extractedText`: string?
- `extractedData`: map
- `issueDate`: string?
- `expiryDate`: string?
- `notes`: string?
- `linkedEventId`: string?
- `createdAt`: Timestamp
- `updatedAt`: Timestamp

The Firestore document ID is the document ID.

## Reminder Document

Path:

```text
users/{userId}/pets/{petId}/reminders/{reminderId}
```

Fields:

- `userId`: string
- `petId`: string
- `title`: string
- `description`: string?
- `dateTime`: Timestamp
- `repeatType`: string?
- `relatedEventId`: string?
- `isCompleted`: bool
- `createdAt`: Timestamp
- `updatedAt`: Timestamp

The Firestore document ID is the reminder ID.

## SmartMessage Document

Path:

```text
users/{userId}/pets/{petId}/smartMessages/{messageId}
```

Fields:

- `userId`: string
- `petId`: string
- `originalText`: string
- `detectedIntent`: string
- `extractedData`: map
- `suggestedActions`: list<map>
  - `type`: string
  - `payload`: map
- `confidence`: number
- `status`: string
- `createdAt`: Timestamp

AI-generated data remains draft data until the user confirms. Gemini must not
write this document directly.

## VetSummaryExport Document

Path:

```text
users/{userId}/pets/{petId}/vetSummaryExports/{exportId}
```

Fields:

- `userId`: string
- `petId`: string
- `fileUrl`: string?
- `storagePath`: string?
- `createdAt`: Timestamp

The Firestore document ID is the export ID.

## Storage References

Firestore should store both the download URL and storage path when available:

- `fileUrl`: user-facing downloadable URL.
- `storagePath`: Firebase Storage path used for delete/replace operations.

Use the existing storage path helpers for:

- profile photos
- document originals
- document scans
- vet summary exports

## Mapper Placement

Future mapper code should live in feature data layers, for example:

```text
lib/features/pets/data/mappers/pet_firestore_mapper.dart
lib/features/timeline/data/mappers/pet_event_firestore_mapper.dart
lib/features/documents/data/mappers/pet_document_firestore_mapper.dart
lib/features/reminders/data/mappers/reminder_firestore_mapper.dart
lib/features/smart_input/data/mappers/smart_message_firestore_mapper.dart
```

Core value object mapping helpers may live under:

```text
lib/core/firebase/firestore/
```

## Follow-Up Implementation Tasks

- Add mapper classes/functions after this plan is accepted.
- Add pure unit tests for value object and mapper round trips.
- Implement Firebase repositories in Phase 3 using these mapping contracts.
