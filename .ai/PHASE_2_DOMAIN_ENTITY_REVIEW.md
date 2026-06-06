# Phase 2 Domain Entity Review

## Scope

Reviewed current domain entities against `PawVault_MVP_Spec_Firebase_Gemini.md`.
This review covers model coverage only. It does not implement new domain
behavior, repository methods, or Firestore mappings.

## Entity Coverage

### Pet

Spec fields are represented:

- `id`
- `userId`
- `name`
- `species`
- `breed`
- `birthDate`
- `gender`
- `weight`
- `microchipNumber`
- `photoUrl`
- `allergies`
- `chronicConditions`
- `notes`
- `createdAt`
- `updatedAt`

Follow-up modeling decisions:

- Consider `PetGender` instead of free-form `String`.
- Consider value objects for IDs and weight.
- Decide whether `photoUrl` should remain `Uri` in domain and serialize as
  `String` at the data layer.

### PetEvent

Spec fields are represented:

- `id`
- `userId`
- `petId`
- `type`
- `title`
- `description`
- `date`
- `nextReminderDate`
- `attachments`
- `source`
- `createdAt`
- `updatedAt`

Spec enum values are represented for `PetEventType` and `PetEventSource`.

Follow-up modeling decisions:

- Consider an attachment value object instead of `List<Uri>`.
- Decide whether `date` should be required for all event drafts.
- Add Firestore timestamp mapping rules in the mapping plan.

### PetDocument

Spec fields are represented:

- `id`
- `userId`
- `petId`
- `title`
- `type`
- `fileUrl`
- `storagePath`
- `extractedText`
- `extractedData`
- `issueDate`
- `expiryDate`
- `notes`
- `linkedEventId`
- `createdAt`
- `updatedAt`

Spec enum values are represented for `PetDocumentType`.

Follow-up modeling decisions:

- Consider structured extracted data instead of `Map<String, Object?>`.
- Decide whether `fileUrl` is required before upload is complete.

### Reminder

Spec fields are represented:

- `id`
- `userId`
- `petId`
- `title`
- `description`
- `dateTime`
- `repeatType`
- `relatedEventId`
- `isCompleted`
- `createdAt`
- `updatedAt`

Follow-up modeling decisions:

- Add a `ReminderRepeatType` enum or value object.
- Decide timezone handling for `dateTime`.

### SmartMessage

Spec fields are represented:

- `id`
- `userId`
- `petId`
- `originalText`
- `detectedIntent`
- `extractedData`
- `suggestedActions`
- `confidence`
- `status`
- `createdAt`

Spec intent values are represented in `SmartMessageIntent`.

Follow-up modeling decisions:

- Expand `SmartMessageStatus` to cover the lifecycle needed for draft review,
  confirmation, save failure, and dismissal.
- Replace `suggestedActions` maps with typed action models before implementing
  save confirmation.
- Keep all Gemini output as drafts. Gemini must not write directly to
  Firestore.

### SmartInputDraft

Current draft entity is intentionally minimal:

- `originalText`
- `requiresConfirmation`

Follow-up modeling decisions:

- Align the draft with Gemini JSON outputs: intent, confidence, extracted data,
  suggested actions, and low-confidence review hints.
- Keep draft persistence and confirmed saves separate.

## Gaps To Carry Forward

- Add value objects/enums for IDs, dates, repeat type, gender, AI statuses, and
  suggested action types where useful.
- Expand repository interfaces after domain contracts are clarified.
- Add Firestore mapping plan for `DateTime`, `Uri`, nested maps, enums, and
  server timestamps.
- Add focused pure tests for mapping/value-object behavior once those are
  implemented.

## Result

The existing domain entities cover the main spec fields and enum lists. The
remaining work is refinement of types, lifecycle states, AI draft shape, and
Firestore mapping contracts.
