# PawVault Tasks

## Phase 1: App skeleton, routing, theme, DI placeholder, Firebase-ready setup

- [x] Create feature-based folder structure under `lib/features`.
- [x] Add Bloc/Cubit dependency and initial Cubits for placeholder flows.
- [x] Add AutoRoute dependency and route definitions.
- [x] Create placeholder screens for pet list, pet profile, timeline, documents,
  reminders, smart input, and vet summary export.
- [x] Add light and dark theme shell.
- [x] Add dependency injection placeholder with repository providers.
- [x] Add Firebase-ready dependencies for Auth, Firestore, Storage, Core, and AI
  Logic.
- [x] Add Firebase-ready app options and platform config files.
- [x] Add Firebase-ready auth, storage, Firestore, and AI data source adapters.
- [x] Add autonomous agent workflow files: `AGENTS.md`, `.ai/ROADMAP.md`,
  `.ai/TASKS.md`, `.ai/PLANS.md`, and README workflow notes.
- [x] Review Phase 1 architecture boundaries and remove any accidental feature
  behavior beyond placeholders.
- [x] Confirm project-level Codex MCP config works, or document the required
  global MCP config if project-level config is not picked up.

## Phase 2: Domain models and Firebase contracts

- [x] Review domain entities against `PawVault_MVP_Spec_Firebase_Gemini.md`.
- [x] Add missing value objects/enums for IDs, dates, event types, document
  types, reminder repeat types, and AI draft statuses where useful.
- [x] Expand repository interfaces with read/write method contracts, without
  implementing Firebase behavior yet.
- [x] Add model mapping plan for Firestore documents and timestamps.
- [x] Add focused tests for value objects, pure model code, or mapping code once
  mappings exist.

## Phase 3: Firebase Auth, Firestore repositories, Storage repositories

- [x] Add Firebase startup path that initializes Firebase only when
  `AppDependencies.firebaseReady(...)` is selected.
- [x] Configure Firestore offline persistence settings in the Firebase startup
  path.
- [x] Add anonymous auth bootstrap contract that signs in when no Firebase user
  exists.
- [x] Add core Firestore mapper helpers for `EntityId`, `DateOnly`,
  `UtcDateTime`, enums, `Uri`, and server timestamps.
- [x] Add pure mapper tests for core Firestore mapper helpers.
- [x] Add Firestore mapper for `Pet` with round-trip tests.
- [x] Add Firestore mapper for `PetEvent` with round-trip tests.
- [x] Add Firestore mapper for `PetDocument` with round-trip tests.
- [x] Add Firestore mapper for `Reminder` with round-trip tests.
- [x] Add Firestore mapper for `SmartMessage` with round-trip tests.
- [x] Add Firestore mapper for `VetSummaryExport` with round-trip tests.
- [x] Implement Firebase `PetRepository` using the mapper and existing
  repository contract.
- [x] Implement Firebase `TimelineRepository` using the mapper and existing
  repository contract.
- [x] Implement Firebase `DocumentRepository` using the mapper and existing
  repository contract.
- [x] Implement Firebase `ReminderRepository` using the mapper and existing
  repository contract.
- [x] Implement Firebase `SmartInputRepository` persistence methods without
  allowing Gemini to write directly to Firestore.
- [x] Implement Firebase `VetSummaryExportRepository` using the mapper and
  existing repository contract.
- [x] Confirm `StorageRepository` upload/delete contracts align with Firebase
  Storage paths and document/photo/export use cases.
- [x] Add repository-level tests with fake or mocked data sources where useful.
- [x] Update `AppDependencies.firebaseReady(...)` to use Firebase repositories
  after mappers and repository implementations are tested.
- [x] Run a Phase 3 architecture boundary review to confirm UI and Cubits still
  do not access Firebase SDKs directly.

## Phase 4: Pet CRUD

- [x] Add Phase 4 actionable task checklist.
- [x] Implement `PetListCubit` watch/load behavior with fake repository tests.
- [x] Update the pet list screen to render repository-backed loading, empty,
  error, and populated states.
- [x] Implement `PetProfileCubit` load behavior for a single pet with fake
  repository tests.
- [x] Add pet form/input state model and validation rules.
- [x] Implement create/update pet Cubit methods with fake repository tests.
- [x] Implement delete pet Cubit method with fake repository tests.
- [x] Replace placeholder pet profile screen with basic read-only pet details.
- [x] Add create/edit pet UI wired through Cubit and repository interfaces.
- [x] Add delete confirmation UI for pet profiles.
- [x] Run a Phase 4 architecture boundary review to confirm widgets still use
  Cubits/repositories and do not access Firebase SDKs directly.

## Phase 5: Timeline and events

- [x] Add Phase 5 actionable task checklist.
- [x] Implement `TimelineCubit` watch/load behavior for timeline events with fake
  repository tests.
- [x] Update the timeline screen to render repository-backed loading, empty,
  error, and populated states.
- [x] Add event filtering by type and date range in `TimelineCubit`.
- [x] Add timeline event form/input state model and validation rules.
- [x] Implement create/update event Cubit methods with fake repository tests.
- [x] Implement delete event Cubit method with fake repository tests.
- [x] Replace placeholder timeline screen with event list display.
- [x] Add create/edit event UI wired through Cubit and repository interfaces.
- [x] Add delete confirmation UI for timeline events.
- [x] Run a Phase 5 architecture boundary review to confirm widgets still use
  Cubits/repositories and do not access Firebase SDKs directly.

## Phase 6: Documents and document upload

- [x] Add Phase 6 actionable task checklist.
- [ ] Implement `DocumentsCubit` watch/load behavior for documents with fake
  repository tests.
- [ ] Update the documents screen to render repository-backed loading, empty,
  error, and populated states.
- [ ] Add document filtering by type (and optional expiring-soon view) in
  `DocumentsCubit`.
- [ ] Add document form/input state model and validation rules (title, type,
  issue/expiry dates, notes).
- [ ] Add a storage upload service/use case that picks a file and uploads bytes
  through `StorageRepository`, returning the file URL and storage path.
- [ ] Implement create/update document Cubit methods that upload via
  `StorageRepository` then persist metadata via `DocumentRepository`, with fake
  repository tests.
- [ ] Implement delete document Cubit method that removes both the storage file
  and the Firestore metadata, with fake repository tests.
- [ ] Replace placeholder documents screen with a document list display
  (title, type, expiry, thumbnail/icon).
- [ ] Add upload/create/edit document UI wired through Cubit and repository
  interfaces, including file picking and progress/error feedback.
- [ ] Add delete confirmation UI for documents.
- [ ] Run a Phase 6 architecture boundary review to confirm widgets still use
  Cubits/repositories and do not access Firebase SDKs/Storage directly.
