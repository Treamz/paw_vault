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
- [ ] Add Firestore mapper for `PetEvent` with round-trip tests.
- [ ] Add Firestore mapper for `PetDocument` with round-trip tests.
- [ ] Add Firestore mapper for `Reminder` with round-trip tests.
- [ ] Add Firestore mapper for `SmartMessage` with round-trip tests.
- [ ] Add Firestore mapper for `VetSummaryExport` with round-trip tests.
- [ ] Implement Firebase `PetRepository` using the mapper and existing
  repository contract.
- [ ] Implement Firebase `TimelineRepository` using the mapper and existing
  repository contract.
- [ ] Implement Firebase `DocumentRepository` using the mapper and existing
  repository contract.
- [ ] Implement Firebase `ReminderRepository` using the mapper and existing
  repository contract.
- [ ] Implement Firebase `SmartInputRepository` persistence methods without
  allowing Gemini to write directly to Firestore.
- [ ] Implement Firebase `VetSummaryExportRepository` using the mapper and
  existing repository contract.
- [ ] Confirm `StorageRepository` upload/delete contracts align with Firebase
  Storage paths and document/photo/export use cases.
- [ ] Add repository-level tests with fake or mocked data sources where useful.
- [ ] Update `AppDependencies.firebaseReady(...)` to use Firebase repositories
  after mappers and repository implementations are tested.
- [ ] Run a Phase 3 architecture boundary review to confirm UI and Cubits still
  do not access Firebase SDKs directly.
