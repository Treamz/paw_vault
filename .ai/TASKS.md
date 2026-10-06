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
- [x] Log key product events from the relevant Cubits (pet created, timeline
  event added, document uploaded, reminder created, smart input used, vet
  summary exported, sign-in) through the analytics port.
- [x] Set a non-identifying analytics user id from the signed-in user and clear
  it on sign-out.
- [x] Document the analytics event taxonomy and how to view it in the Firebase
  console (docs/ANALYTICS.md).
- [x] Run a Phase 13 architecture boundary review to confirm widgets/Cubits use
  the analytics port and never the Firebase Analytics SDK directly.

## Phase 14: Monetization (RevenueCat)

- [x] Add `purchases_flutter` and a `SubscriptionService` port with a RevenueCat
  implementation and a no-op (local-first) implementation; expose entitlement
  state (`isPro`) reactively and wire it through `AppDependencies` + providers.
- [x] Configure RevenueCat at bootstrap (public SDK key) and identify the user
  with the Firebase uid on sign-in/out (`logIn`/`logOut`).
- [x] Build a paywall screen + Cubit driven by RevenueCat offerings, with
  purchase and restore flows; log paywall/purchase analytics events.
- [x] Gate adding a second pet behind Pro (free limit = 1), routing to the
  paywall; grandfather existing pets.
- [x] Gate Smart Input and AI document scanning behind Pro, routing to the
  paywall.
- [ ] Set up store products: an annual auto-renewable subscription with a free
  trial in App Store Connect (and Play Console), plus the RevenueCat
  entitlement (`pro`), offering, and a dashboard **Paywall** for that offering;
  document the setup (docs/MONETIZATION.md).
- [x] Run a Phase 14 architecture boundary review to confirm widgets/Cubits use
  the subscription port and never the RevenueCat SDK directly.

## Phase 15: Paw Scan

- [x] Add Phase 15 roadmap entry and actionable task checklist.
- [x] Add Paw Scan domain entities and enums: `PawAttentionLevel`,
  `PawLocation`, `PawObservation`/`PawObservationArea`, `PawScanDraft`
  (transient, with `PawScanPhotoQuality` + `PawScanDraftStatus`), and the
  persisted `PawCheck`, with value-object tests.
- [x] Add `PawScanSafetyFilter` (pure Dart) that scrubs diagnostic and
  treatment language from model output, may only raise an attention level, and
  flags the draft low-confidence when it fires. Heavily tested.
- [x] Add `PawScanAiRepository` and `PawCheckRepository` domain contracts plus
  the `PawPhotoPicker` port.
- [x] Extend `FirebaseAiLogicDataSource` with `analyzePaw(...)`; implement it in
  `FlutterFireAiLogicDataSource` using a dedicated model factory with
  `responseSchema` and a safety-hardened system instruction, plus a static
  `parsePawScanDraft` that degrades to `undetermined` (never "nothing notable")
  and always runs the safety filter. Add the no-op implementation.
- [x] Add `pawChecks` to the account-deletion subcollection allowlist in
  `FirebaseAccountDeletionService` so deleted accounts leave no paw checks
  behind. (`weightEntries` is missing there too — tracked separately.)
- [x] Add the Paw Scan AI repository adapters (Firebase-ready + no-op) and the
  `PawPhotoPicker` implementation that downscales via `image_picker`.
- [x] Add the `pawChecks` Firestore path, the `pawCheckPhoto` Storage path, the
  `PawCheckFirestoreMapper` with round-trip tests, and the `PawPhotoUploadService`.
- [x] Implement the Paw Check data layer: data source interface, Firestore data
  source, Firebase repository (enforcing the confirmed-before-save invariant),
  and the local repository, with tests.
- [x] Implement `PawScanCubit`: capture, analyze, review, retake, confirm,
  dismiss, delete, and the watched journal, with fake-repository tests.
- [x] Add the Paw Scan screen (Scan + Journal tabs), the non-dismissible
  disclaimer, the attention badge, and the retake prompt, with widget tests.
- [x] Add the paw check comparison screen (before/after for the same paw).
- [x] Add `PawScanReminderSuggestion`: deterministic, on-device follow-up
  timing per attention level (the model must not author advice), with tests.
- [x] Wire the follow-up reminder suggestion into the existing reminder form
  route (pre-filled, saved only by the user).
- [x] Include opted-in paw checks in `VetSummaryData` and render a "Paw checks"
  section with its disclaimer in the exported PDF.
- [x] Wire Paw Scan through `AppDependencies`, `app.dart` providers, the router,
  the pet profile records card (Pro-gated), and analytics events.
- [x] Add `docs/PAW_SCAN.md` documenting the safety model, the prompt, the filter
  lexicon, and the App Review notes; update the README feature list.
- [~] Add an integration test covering capture -> analyze -> confirm -> journal.
  Written (`integration_test/paw_scan_flow_test.dart`, 3 cases: confirm saves,
  discard writes nothing, a non-paw photo shows no attention level) and it
  compiles and analyzes clean, but it has **not been executed**: on this machine
  `flutter test integration_test/...` hangs after installing on the iOS 26
  simulator (app installed, zero CPU, no output) rather than attaching to the
  VM service. Run it on a working device/simulator before relying on it.
- [x] Run a Phase 15 architecture boundary review to confirm widgets/Cubits use
  ports and repositories and never touch Firebase AI, Firestore, or Storage SDKs
  directly. Verified: nothing under `paw_scan/presentation` or
  `paw_scan/domain` imports a Firebase/image_picker SDK; the only SDK
  touchpoints are `flutter_fire_paw_check_data_source.dart` and
  `paw_photo_picker_impl.dart`; no cubit or widget imports `paw_scan/data`;
  and `app_dependencies.dart` is the sole composition point.

## Dev tooling

- [x] Add `DevSeeder` and a debug-only `--dart-define=PAWVAULT_SEED=true` path
  that fills a signed-in account with `SampleData` (pets, timeline, documents,
  reminders, smart input history, paw checks, weight history), keyed to the
  real uid and skipped when the account already has pets. Documented in
  `docs/TEST_ACCOUNT.md`.

## Phase 15 follow-ups

- [x] Make Paw Scan capture camera-first: one tap to the camera (no
  source-picker sheet), "Choose from gallery" beside it, the paw selector shown
  only once a photo exists, and the action emphasis moving to Describe once
  there are photos (back to the camera after a rejection).
- [ ] Add a "Report this result" action to the Paw Scan result and journal
  screens (a prefilled `mailto:` via the existing `url_launcher`). Google
  Play's GenAI policy requires an in-app way to report offensive AI output.
  `PawScanCopy.reportResult` was removed as dead code when the camera-first
  change landed; reintroduce it with the action.

## Phase 16: Paid acquisition (Apple Search Ads)

- [x] Write the Apple Search Ads campaign plan (`docs/ASA.md`): Brand + Exact at
  $10/day US, Competitor and Discovery documented but off, negative-keyword
  strategy, ad-copy claim rules, and what to read after two weeks.
- [x] Ship ASA install attribution: an `InstallAttributionService` port
  (mirroring `lib/core/tracking/`) with a RevenueCat and a no-op
  implementation, enabled in `app.dart` *after* the ATT prompt resolves. No
  build change was needed: `RevenueCat.framework` already links
  `AdServices.framework`, which is what enables Firebase's reporter. An
  explicit `-framework AdServices` in `ios/Flutter/*.xcconfig` was tried and
  removed — the linker dead-strips it because `Runner` references no AdServices
  symbol, so it was inert config that looked load-bearing.
  The original design — fetch the token in Dart, POST it to Apple, log campaign
  fields — was **wrong**: both Firebase (`APMSearchAdReporter`) and RevenueCat
  already implement the whole flow natively, including the retry ladder and the
  once-per-install flag. Firebase's was disabled only because AdServices was
  not linked. Doing it in Dart would have reimplemented shipped native code and
  been the one design that puts a raw install identifier into Dart, against
  `docs/ANALYTICS.md`.
- [ ] Re-review the App Store Connect **App Privacy** answers for Advertising
  Data / Product Interaction now that ASA attribution is collected. Note
  AdServices is first-party and is not "tracking" under Apple's definition, so
  if ASA is the only reason a "used to track you" flag is set, that flag is
  wrong. (Checked: AdServices is *not* on Apple's required-reason API list, so
  the missing app-level `PrivacyInfo.xcprivacy` is not a blocker for this —
  re-verify the list at submission time.)
- [ ] Add an app-level `ios/Runner/PrivacyInfo.xcprivacy` — it does not exist,
  while every Pod ships one, and the app already shows an ATT prompt without a
  manifest declaring the behaviour. Independent of ASA.
- [ ] **Deferred (paid plan):** the RevenueCat → Apple Search Ads integration.
  Until it is on, `AppBootstrap` wires `NoopInstallAttributionService` so no
  per-install identifier is posted to a service that would do nothing with it.
  GA4 campaign attribution works without it via Firebase's own reporter; what
  is missing is revenue/LTV per campaign. Flip one line in
  `_configureSubscriptions()` when the plan is upgraded.
- [ ] Add an in-app rating prompt (`SKStoreReviewController`) after a natural
  success moment, e.g. the first vet-summary export. The listing has 8 reviews,
  which caps ad conversion and organic ranking; `docs/ASO.md` §9 recommends this
  independently of the ads work.
- [ ] Update the App Store listing to mention Paw Scan once 1.0.9 is released —
  the live description still lists only Smart Input and document scanning.

## QA fixes

- [x] Documents: a document scanned from several pages saved only the first
  file. `DocumentExtractionCubit.confirmExtraction` uploaded
  `pickedFiles.firstOrNull`, and `PetDocument` could hold one file anyway, so
  the rest were silently discarded — the owner lost data with no warning.
  Added `DocumentAttachment` + `PetDocument.attachments` (legacy `fileUrl`/
  `storagePath` kept and still populated, so an older build shows one file
  rather than none), a per-attachment Storage path, multi-file upload, and
  rendering of every attachment.
- [x] Documents: attachments took 2–3s to appear on first open. The previews
  live inside the details sheet and used `Image.network`, which has no disk
  cache, so nothing loaded until the sheet opened. Switched to
  `CachedNetworkImage` and warm the cache when the list arrives, so the first
  open is instant too.
- [x] Found while fixing the above, same root cause, not reported by QA:
  editing a multi-attachment document dropped the extra files (`updateDocument`
  rebuilt from the legacy pair), and deleting one orphaned them in Storage
  (`deleteDocument` removed a single path).
- [ ] **Screenshot capture is broken repo-wide**, not just for this fix. Every
  PNG from `flutter drive --driver=test_driver/screenshots.dart` comes out
  blank white and byte-identical — verified by running the known-good
  `integration_test/screenshots_test.dart`, whose output has the same MD5 as a
  blank frame. **This means `tool/screenshots.sh` currently produces blank App
  Store screenshots.**
  **Two causes, both confirmed; `convertFlutterSurfaceToImage()` is NOT one
  of them** (an earlier note in this file blamed it — that was wrong).
  `integration_test/smart_input_scan_history_test.dart` calls both
  `convertFlutterSurfaceToImage()` and `takeScreenshot()` and produced
  correct, distinct PNGs (192 KB, 127 KB, 178 KB) on the iPhone 16 simulator,
  so the binding works on iOS.
  1. **The notification permission alert.** `AppDependencies.localFirst()`
     wires `LocalReminderNotificationScheduler`, so the app asks for
     notification permission at startup. The system alert covers the app, and
     every capture is then the same blank grey frame — 58815 bytes, MD5
     `51677bbf…`, which is the hash every blank screenshot in this repo shares.
     `flutter drive` reinstalls the bundle, which resets the permission, so
     the prompt comes back on most runs; the one run that produced real PNGs
     was one where it had already been answered. Proper fix: give the
     screenshot/integration harness a no-op reminder scheduler so it never
     asks. Workaround: answer the prompt on the simulator and re-run.
  2. **`screenshots_test.dart` additionally throws `ProviderNotFoundException`**
     for `_AccountActionButton` and `_PetProfileView` — the suite does not
     supply `RepositoryProvider`s the widget tree has since grown, so those
     screens cannot build even once the alert is gone. Its provider list needs
     bringing back in line with the app.
  Until (1) is fixed, visual verification can also go through
  `xcrun simctl io <udid> screenshot`, which reads the device framebuffer
  directly — but note it shows the alert too, so dismiss it either way.
- [x] **Documents: make the issue date clearly required.** It already was —
  both `PetDocumentFormState.validate()` and the two creation paths reject a
  document without one, since 2026-08-08 — so no document created today can
  lack a date. What was missing was (a) any sign that it is required, and
  (b) a sensible treatment of the documents saved *before* that, which is
  what QA's screenshot shows. Now: the field reads "Issue date (required)"
  and no longer offers a clear action; the scan review form shows the
  field-level error instead of only a generic "Please fix validation errors"
  snackbar (a scan often cannot read a date off the page); a document with no
  date says "No date" on its tile; and those documents sort last as a group
  rather than being slotted in by their invisible `createdAt`, which is what
  made their position unexplainable. Editing one forces a date, so they get
  fixed as they are touched. Nothing backfills them — there is no honest
  value to invent.
- [x] **Time picker: the keyboard now opens on the first tap of its icon.**
  Tapping the keyboard toggle built the hour and minute fields but focused
  neither, so the keyboard stayed shut until the field was tapped as well.
  This is Material's own behaviour, confirmed by probe: after the toggle no
  text field holds focus, and `initialEntryMode: input` is no better — the
  framework only autofocuses when the dial is *double*-tapped, which nobody
  finds. Fixed from the caller with `onEntryModeChanged`, advancing focus once
  into the dialog, which lands on the hour field.
  Only the reminder form is affected: it holds the app's single
  `showTimePicker`, and every date picker is deliberately
  `DatePickerEntryMode.calendarOnly` (manual entry demands a strict
  mm/dd/yyyy and produced "Invalid format" confusion), so none of them offers
  a keyboard toggle at all.
  The focus hop depends on the dialog's traversal order, so
  `reminder_form_screen_test.dart` asserts the hour field really ends up
  focused — a Flutter upgrade that reorders it fails the test instead of
  quietly focusing a button.
- [x] **Smart Input scan: the attached files are now visible before saving.**
  The review form stated only "N pages attached", so there was no way to
  check which photo had been picked without discarding and starting again.
  It now shows a thumbnail per attached page, read straight from the picked
  bytes (nothing is uploaded until Confirm & save). Tapping an image opens it
  full screen with pinch-zoom, reusing `showFullScreenImage`; tapping a PDF
  opens it in `PdfPreview`, the same in-app viewer the vet summary uses. A
  file of any other kind shows an extension tile and says it has no preview
  rather than ignoring the tap.
- [x] **Scan: the issue date row goes red, and the prompt works harder to
  find the date.** The field-level error already landed with the "issue date
  required" work; it coloured only the subtitle, so now the title, the message
  and the trailing calendar icon all turn red — the row reads as the required
  field it is. The extraction prompt now tells the model where issue dates
  hide on pet documents ("issued", "date of issue", "vaccination date",
  "administered", "visit date", "prescribed on", stamps), to expand a
  two-digit year, and to return null rather than guess — a health record must
  never carry an invented date. An empty field is still a valid outcome, which
  is exactly when the red row earns its keep.
- [x] **Scan: the expiry date is filled in when the document says so, and can
  be removed.** It stays optional. The prompt now looks for the wording that
  marks one ("expires", "expiry", "valid until", "valid through", "next due",
  "booster due") and is told to leave the field null when no such wording
  appears and never to derive one from the issue date. Because the scan can
  now fill it in — and can misread it — the row has a clear (✕) action, which
  replaces the calendar icon only while a date is set. There is nothing to
  fall back to on an optional field, so removing it had to be possible.
- [x] Found while doing the above, not reported: picking a date cleared *every*
  field error, so a missing title stopped being flagged until the next save
  attempt. The pickers now re-validate instead. Type and Title also had the
  issue date's original problem — required, but failing with only a generic
  snackbar — so both now show their own `errorText`.
- [x] **Documents: attachments are announced instantly, and the row says a
  file is there.** Re-reported by QA after the first attempt — the earlier fix
  added `CachedNetworkImage` plus a best-effort `precacheImage`, which only
  helped the *second* open. Root cause of what remained: the sheet's image had
  **no `placeholder`**, so it rendered an empty 220px box for the whole
  download and the document looked as though it had nothing attached. It now
  shows a loading box immediately, and the default 500ms fade is cut to 120ms.
  Each row also carries a paperclip with the file count — no network involved,
  so it is correct the instant the list paints, including for PDFs — plus a
  40px thumbnail of the first photo on the trailing edge. The thumbnail is
  what actually shortens the wait: a mounted image widget really does drive
  the download and fill the shared disk cache, where `precacheImage` only
  tried, and only when the list changed.
  **Not claimed: a cold first open is not instant.** The bytes have to come
  from Storage once. What changed is that it is never ambiguous, and by the
  time a row has painted its thumbnail the sheet reads from disk. Genuinely
  removing the download would need server-side thumbnails (the Firebase
  Resize Images extension), which is infrastructure, not app code.
  The leading circle still shows the type icon — a deliberate earlier choice
  for scannability — so the thumbnail went to the trailing edge instead.
- [x] **Smart Input History matches Documents for attachments.** The sheet
  already showed every attached file; what was missing was the row indicator
  and, less visibly, the same empty-box bug — History's preview had no
  `placeholder` either, so it looked like nothing was attached while a photo
  downloaded. Both screens now share
  `documents/presentation/widgets/attachment_views.dart`
  (`AttachmentLabel`, `AttachmentPreview`, `AttachmentThumbnail`), which is
  why they can no longer drift: the duplicated previews had already drifted
  once, only one of them gaining the placeholder.
  A History row now carries the same paperclip and file count as a document
  row, and a scanned entry shows its photo as a thumbnail in the leading slot.
  The AI glyph stands in there while the photo loads or if it cannot be
  loaded, so the slot is never empty — the paperclip carries the "has files"
  signal regardless, which is why the glyph no longer doubles as an
  attachment marker.
  Smart Input depending on the documents feature is deliberate and
  pre-existing: a scanned analysis keeps the same `DocumentAttachment`s the
  document got.
- [x] **Gallery multi-select everywhere it means something.** Nothing in the
  app used `pickMultiImage` — not even Paw Scan, which QA cited as already
  having it; what Paw Scan has is the ability to *hold* four photos, added one
  at a time. All four pickers gained a `pickMultipleFromGallery()` (or
  `pickDocuments()`) alongside the single-pick method the camera still needs,
  and four screens now use it: Paw Scan, the document scan, the timeline event
  form and the document form.
  Paw Scan keeps the first four of an over-selection and says how many were
  left out, rather than refusing the lot. The document scan analyses every
  page picked in one AI request. The document form's picker now **appends**
  instead of replacing, with a per-file remove and an "Add more" button —
  which closes the separate task below about it attaching one file at a time.
  A single file there now goes through the same `attachment_N` storage path
  the scanner uses, so a hand-made and a scanned document are stored alike;
  the legacy `fileUrl`/`storagePath` pair stays populated for older builds.
  **Deliberately excluded:** the pet profile photo. It is one avatar, so
  multi-select has nothing to mean there. The file browser's single-pick path
  is also unchanged — the request was about the gallery.
- [ ] **`integration_test/paw_scan_flow_test.dart` fails on this branch**, and
  did so before the multi-select work — verified by stashing the change and
  re-running: identical `+1 -3`. Image-resource exceptions during the journal
  thumbnails, so likely the same noop-storage relative URI that makes
  thumbnails unloadable in local-first. Needs its own look.
- [x] **Timeline keyboard that would not go away.** Reported as intermittent,
  surviving the way out to the main menu, and only cured by killing the app.
  Mechanism found in the code: the form's fields are `enabled: !isSaving`, so
  the moment saving starts a field that still holds focus is *disabled*, which
  tears its input connection down abruptly — and the same cubit transition
  pops the route from a `BlocListener`. The platform is told to close a
  connection belonging to a field and a route that are both already going, and
  iOS can be left showing a keyboard with nothing focused anywhere, which no
  later screen can dismiss. That also explains "sometimes": it needs a field
  to still be focused when Save is tapped, and on iOS tapping a button does
  not take focus off a text field.
  Fix: give up focus *first*, while the field is still mounted and enabled, so
  the keyboard closes the ordinary way — on save, on cancel, on the two
  programmatic pops, and before the date and photo pickers take over.
  The same `enabled: !isSaving` pattern exists in the pet form, Paw Scan's
  note field and Smart Input's input, so each of those now unfocuses on submit
  too. QA only hit Timeline, but the defect is identical.
  **Not verified end to end.** The discriminating condition cannot be
  reproduced in a test: `tester.tap` releases focus from a text field where
  iOS does not, so by the time the form disables its fields the test has
  already unfocused. The new integration test pins the weaker invariant that
  no field keeps focus after the form closes. Confirming the fix needs a
  device with the simulator's hardware keyboard disconnected, and an
  intermittent bug makes a single manual pass inconclusive either way.
- [x] **Timeline event reminders take a time, not just a date.** `PetEvent`
  already stored `nextReminderDate` as a full `UtcDateTime`, so nothing in the
  entity, mapper or validation had to change — the form simply had no way to
  set the time of day. Added a "Reminder Time" row beside the date, with the
  keyboard-entry focus fix applied (that helper moved to
  `core/presentation/widgets/time_picker_keyboard_focus.dart` now that the
  reminder form and this one both use it).
  Choosing a date keeps a time already picked, and choosing a time before a
  date takes the event's day. A date picked on its own lands on 09:00 rather
  than midnight, which reads as "no time was set". The time is now shown
  wherever the reminder is — the tile and the detail sheet — otherwise setting
  it would be invisible.
- [ ] **An event's reminder does not notify.** Found while adding the time
  above, and worth deciding on: `nextReminderDate` is only ever rendered on
  the timeline tile and in the event detail. Nothing schedules a local
  notification from it — `ReminderNotificationScheduler` is wired to the
  Reminders feature alone. So an event reminder is a note to self that the app
  shows, not something that will alert the owner, and a time makes it read
  more like a promise than it was before. Either wire event reminders through
  the scheduler (and cancel/reschedule them when the event is edited or
  deleted), or relabel the field so it does not promise a notification.
- [x] The document **form** attached one file at a time, replacing rather than
  appending. Fixed with the gallery multi-select work above.
