# Phase 2 Value Objects And Enums

## Scope

Added useful domain value objects and enums identified by the Phase 2 domain
entity review. This task did not add repository behavior, Firebase mappings, or
feature workflows.

## Added Value Objects

- `EntityId` for domain identifiers.
- `DateOnly` for date-only fields such as birth date, issue date, and expiry
  date.
- `UtcDateTime` for timestamp and scheduled date-time fields.
- `PetWeight` with `PetWeightUnit`.

## Added Or Refined Enums

- `PetGender`
- `ReminderRepeatType`
- `SmartInputDraftStatus`
- Expanded `SmartMessageStatus`
- `SmartSuggestedActionType`

Existing spec enums were kept:

- `PetEventType`
- `PetEventSource`
- `PetDocumentType`
- `SmartMessageIntent`

## Entity Updates

- Pet IDs now use `EntityId`.
- Pet birth date now uses `DateOnly`.
- Pet gender now uses `PetGender`.
- Pet weight now uses `PetWeight`.
- Event, reminder, smart message, and document IDs now use `EntityId`.
- Timestamp fields now use `UtcDateTime`.
- Reminder repeat type now uses `ReminderRepeatType`.
- Smart suggested actions now use typed `SmartSuggestedAction` entries.
- Smart input drafts now include draft status, intent, confidence, extracted
  data, and suggested actions while remaining confirmation-first.

## Follow-Up

- Define Firestore serialization rules for all value objects.
- Add pure tests for value object equality, ordering, and mapping once mapper
  code exists.
