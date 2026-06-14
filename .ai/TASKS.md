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
- [x] Implement `DocumentsCubit` watch/load behavior for documents with fake
  repository tests.
- [x] Update the documents screen to render repository-backed loading, empty,
  error, and populated states.
- [x] Add document filtering by type (and optional expiring-soon view) in
  `DocumentsCubit`.
- [x] Add document form/input state model and validation rules (title, type,
  issue/expiry dates, notes).
- [x] Add a storage upload service/use case that picks a file and uploads bytes
  through `StorageRepository`, returning the file URL and storage path.
- [x] Implement create/update document Cubit methods that upload via
  `StorageRepository` then persist metadata via `DocumentRepository`, with fake
  repository tests.
- [x] Implement delete document Cubit method that removes both the storage file
  and the Firestore metadata, with fake repository tests.
- [x] Replace placeholder documents screen with a document list display
  (title, type, expiry, thumbnail/icon).
- [x] Add upload/create/edit document UI wired through Cubit and repository
  interfaces, including file picking and progress/error feedback.
- [x] Add delete confirmation UI for documents.
- [x] Run a Phase 6 architecture boundary review to confirm widgets still use
  Cubits/repositories and do not access Firebase SDKs/Storage directly.

## Phase 7: Gemini Smart Text Input

- [x] Add Phase 7 actionable task checklist.
- [x] Implement `SmartInputCubit` submit flow: send user text, receive a
  `SmartInputDraft`, and emit idle/loading/review/error states, with fake
  repository tests (no direct Gemini/Firestore access).
- [x] Add a draft review UI showing detected intent, extracted data, suggested
  actions, and a confidence/low-confidence indicator.
- [x] Implement a confirm action that persists the approved draft as a
  `SmartMessage` (status confirmed) via `SmartInputRepository`, with fake
  repository tests; AI output is never saved without explicit confirmation.
- [x] Implement a dismiss/discard action that drops the draft without saving.
- [x] Add watched smart message history for the pet via
  `watchSmartMessages`, with loading/empty/error/populated states.
- [x] Add AI safety affordances in the UI: label drafts as AI-generated and
  require user verification, with no medical diagnosis framing.
- [x] Run a Phase 7 architecture boundary review to confirm widgets/Cubits do
  not access Firebase/Gemini SDKs directly and AI never writes to Firestore.

## Phase 8: Document scanner and Gemini document extraction

- [x] Add Phase 8 actionable task checklist.
- [x] Add a `DocumentExtractionDraft` domain entity (suggested
  `PetDocumentType`, title, issue/expiry dates, notes, extracted text,
  confidence). Reuses the existing `PickedFile` value object (bytes, MIME,
  extension) from the documents feature.
- [x] Extend the AI port for multimodal document extraction from file bytes +
  MIME type, returning a `DocumentExtractionDraft`; update the noop and Firebase
  AI data sources/repositories (noop returns a stub; AI never writes Firestore).
- [x] Add an image/PDF picker supporting camera capture, gallery, and PDF
  selection. Uses `image_picker` (camera/gallery) + `file_picker` (PDF/image),
  behind a `DocumentSourcePicker` port returning a `PickedFile`.
- [x] Implement a `DocumentExtractionCubit`: pick file, request extraction, and
  emit idle/picking/extracting/review/saving/failure states, with fake tests.
- [x] Implement confirm-and-save: build a `PetDocument` from the edited form and
  the uploaded file via `DocumentUploadService`, persist via
  `DocumentRepository`, with fake tests; nothing saved without confirmation.
- [x] Add the extraction review UI: a pre-filled editable document form (type,
  title, issue/expiry dates, notes) seeded from the draft, with AI/confidence
  affordances.
- [x] Add an entry point from Smart Input ("Attach document or photo") that
  launches the extraction flow when the file is classified as a document.
- [x] Wire AI extraction and the picker through `AppDependencies`/providers and
  register the extraction route.
- [x] Run a Phase 8 architecture boundary review: UI/Cubits use no Firebase/
  Gemini SDKs, AI returns drafts only and never writes to Firestore, and a
  document is saved only after explicit user confirmation.

## Phase 9: Reminders and local notifications

- [x] Add Phase 9 actionable task checklist.
- [x] Implement `RemindersCubit` watch/load behavior with fake repository tests,
  emitting loading/empty/error/populated states.
- [x] Update the reminders screen to render the four repository-backed states.
- [x] Add a reminder form/input state model and validation rules (title,
  date/time, repeat type, optional description).
- [x] Implement create/update reminder Cubit methods with fake repository tests.
- [x] Implement complete and delete reminder Cubit methods with fake repository
  tests.
- [x] Replace placeholder reminders screen with a list display (title,
  date/time, repeat, completed state) sorted by due date.
- [x] Add create/edit reminder UI wired through the Cubit and repository.
- [x] Add complete and delete confirmation UI for reminders.
- [x] Add a local notification port and implementation that schedules a
  notification when a reminder is saved and cancels it on complete/delete.
  Uses `flutter_local_notifications` + `timezone` behind a
  `ReminderNotificationScheduler` port; scheduling is best-effort in the cubit.
- [x] Wire the notification service and reminder form route through
  `AppDependencies`/providers.
- [x] Run a Phase 9 architecture boundary review to confirm widgets/Cubits use
  repositories/ports and do not access Firebase SDKs or the notifications
  plugin directly.

## Phase 10: Vet summary PDF export

- [x] Add Phase 10 actionable task checklist.
- [x] Add a `VetSummaryData` model aggregating the pet profile, timeline events,
  documents, and reminders for a summary.
- [x] Add a summary aggregation use case that loads the data from the feature
  repositories for a pet, with fake-repository tests.
- [x] Add a PDF builder (pure Dart) that renders `VetSummaryData` to PDF bytes
  using the `pdf` package, with tests asserting non-empty output.
- [x] Add a share/print service port and implementation for sharing the
  generated PDF locally, using the `printing` package behind a
  `PdfShareService` port.
- [x] Implement `VetSummaryExportCubit`: generate the PDF, share it, and
  optionally upload to storage and save an export record, with
  idle/generating/ready/sharing/failure states and fake tests.
- [x] Add watched export history via `watchExports` with loading/empty/error/
  populated states.
- [x] Replace the placeholder vet summary screen with generate/preview/share UI
  and the export history list.
- [x] Wire the PDF builder, share service, and aggregation use case through
  `AppDependencies`/providers.
- [x] Run a Phase 10 architecture boundary review: UI/Cubits use ports/
  repositories, and PDF/share/Firebase SDKs stay in the data layer.

## Phase 11: Account auth and cross-device sync

- [x] Add Phase 11 actionable task checklist.
- [x] Extend the `AppUser` entity and `AuthRepository` contract with email and
  credential-based sign-up/sign-in/link methods (email/password, Google,
  Apple), without implementing Firebase behavior yet. Added via an
  `AccountAuthRepository` sub-interface to avoid breaking existing fakes.
- [x] Implement Firebase email/password sign-up that links the credential to the
  current anonymous user (falling back to sign-in when already registered) and
  email/password sign-in, in the auth data source and repository, with
  fake-data-source tests where feasible.
- [x] Add Google sign-in support using the `google_sign_in` package with
  anonymous-account linking, behind the auth abstraction. Platform config
  (OAuth client IDs, iOS URL scheme) tracked in the documentation task.
- [x] Add Apple sign-in support using the `sign_in_with_apple` package with
  anonymous-account linking, behind the auth abstraction. The Sign in with
  Apple capability/entitlement is tracked in the documentation task.
- [x] Implement an `AccountCubit` exposing the signed-in account state and
  sign-up/sign-in/sign-out actions, with fake-repository tests.
- [x] Add a sign-in/sign-up UI (email/password form + Google/Apple buttons)
  reachable from the profile, surfacing errors and linking outcomes.
- [x] Add signed-in account status and sign-out UI (an AccountAction in the pet
  list app bar showing signed-in state, with a sign-out sheet).
- [x] Wire the account route and any new auth providers through
  `AppDependencies`/providers. (Done alongside the account status UI: the
  AccountRoute is registered and AccountAuthRepository is provided.)
- [x] Document the required Firebase and Apple platform configuration for
  Google/Apple sign-in (docs/AUTH_SETUP.md).
- [x] Run a Phase 11 architecture boundary review to confirm widgets/Cubits use
  the auth abstraction and do not access Firebase Auth or provider SDKs
  directly.

## Phase 12: Polish, tests, release candidate

- [x] Add Phase 12 actionable task checklist.
- [x] Extract shared loading/empty/error state widgets and adopt them across the
  feature screens for consistent UX.
- [x] Accessibility pass: add semantic labels/tooltips to icon-only buttons and
  ensure interactive elements meet minimum tap-target sizes.
- [x] Add widget tests for key screens (documents, reminders, smart input, vet
  summary) covering their empty and populated states.
- [x] Tighten lints in `analysis_options.yaml` and resolve any new warnings.
- [x] Review platform configuration (app name, bundle/app id, icons, min SDK
  versions, required permissions) and document any gaps.
- [x] Update the README with the full feature list and run instructions, and
  refresh `.ai` docs to reflect the shipped app.
- [x] Run the full required checks (format, analyze, test) and a manual smoke
  pass of the primary flows; record the release-readiness result.

## Phase 13: Analytics and product insights

- [x] Add the `firebase_analytics` package and an `AnalyticsService` port with
  noop (local) and Firebase implementations, expose it through
  `FirebaseInstances`/`AppDependencies`, and provide it to the widget tree.
- [x] Track screen views automatically via an analytics route observer wired
  into the AutoRoute navigator.
- [ ] Log key product events from the relevant Cubits (pet created, timeline
  event added, document uploaded, reminder created, smart input used, vet
  summary exported, sign-in) through the analytics port.
- [ ] Set a non-identifying analytics user id from the signed-in user and clear
  it on sign-out.
- [ ] Document the analytics event taxonomy and how to view it in the Firebase
  console (docs/ANALYTICS.md).
- [ ] Run a Phase 13 architecture boundary review to confirm widgets/Cubits use
  the analytics port and never the Firebase Analytics SDK directly.
