# PawVault Roadmap

## Phase 1: App skeleton, routing, theme, DI placeholder, Firebase-ready setup

Create the durable app shell and development workflow. Establish routing,
theme, dependency injection placeholders, Firebase-ready package setup, and
placeholder screens without implementing real product behavior.

## Phase 2: Domain models and Firebase contracts

Define domain models, repository interfaces, Firebase data source contracts,
storage path helpers, Firestore path helpers, and AI draft contracts.

## Phase 3: Firebase Auth, Firestore repositories, Storage repositories

Wire Firebase initialization, anonymous auth, Firestore repository
implementations, Storage repository implementations, and Firestore offline
persistence.

## Phase 4: Pet CRUD

Implement creating, reading, updating, and deleting pet profiles through
repositories and Cubits.

## Phase 5: Timeline and events

Implement health timeline event listing, filtering, creation, editing, and
deletion.

## Phase 6: Documents and document upload

Implement document metadata management and Firebase Storage upload flows.

## Phase 7: Gemini Smart Text Input

Implement smart text input that sends user-provided text to Gemini, receives a
structured draft, shows confirmation, and saves only after user approval.

## Phase 8: Document scanner and Gemini document extraction

Implement document scan/import flows, extraction draft creation, review, and
confirmation before saving extracted data.

Decisions (2026-06-07):

- Reachable from Smart Input: the user can attach a file/image there, and if
  Gemini classifies it as a pet document, route into this extraction flow.
- Accept images (camera + gallery) and PDFs.
- Gemini extraction is multimodal: extend `AiRepository` to accept file bytes +
  MIME type and return a draft with a suggested `PetDocumentType` and fields.
- Confirmation is a pre-filled, editable document form (type, title,
  issue/expiry dates, notes); nothing is saved until the user confirms.
- On confirm, upload the file via the existing `DocumentUploadService` and save
  a `PetDocument` via `DocumentRepository`.

## Phase 9: Reminders and local notifications

Implement reminders, repeat rules, completion state, and local notifications.

## Phase 10: Vet summary PDF export

Implement vet summary PDF generation, local sharing/export, and optional
Firebase Storage upload.

## Phase 11: Account auth and cross-device sync

Add real account authentication on top of the existing anonymous bootstrap:
email/password and/or federated sign-in, a login/sign-up UI, linking an
anonymous account to a permanent one (so existing local data is preserved),
sign-out, and signed-in account state. Enables the same archive to be accessed
across devices instead of being tied to a single device's anonymous user.

Decisions (2026-06-12):

- Sign-in methods: email/password, Google, and Apple.
- On sign-up, link the credential to the current anonymous account so existing
  pets/records carry over; fall back to plain sign-in when the credential
  already belongs to an account.
- Sign-in is optional: the app keeps working anonymously and users sign in from
  the profile to back up and sync; no startup login gate.
- Provider/platform configuration (Google client IDs, Sign in with Apple
  capability and Firebase provider enablement) is required and tracked as setup
  tasks; the code is built behind the existing auth abstractions.

## Phase 12: Polish, tests, release candidate

Improve UX, accessibility, error states, empty states, test coverage, platform
configuration, and release readiness.

## Phase 13: Analytics and product insights

Add Google/Firebase Analytics to understand how the app is used and which
features deliver value, behind the existing local-first/Firebase-ready
abstractions. Track screen views automatically and key product events (pet
created, timeline event added, document uploaded, reminder created, smart input
used, vet summary exported, sign-in). Analytics must be a port with noop (local)
and Firebase implementations so it is disabled in local-first mode and never
called directly from widgets/Cubits via the SDK. No personal or medical content
is sent as event parameters — only non-identifying counts and types.

## Phase 14: Monetization (RevenueCat)

Introduce a paid "PawVault Pro" tier using RevenueCat (`purchases_flutter`),
behind the existing local-first/Firebase-ready abstractions.

Model (decided 2026-06-14):

- **Free:** 1 pet; no AI features.
- **Pro:** unlimited pets and AI features (Smart Input + AI document scanning).
- **Plan:** annual subscription with a free trial (intro offer).

Design:

- A `SubscriptionService` port with a RevenueCat implementation and a no-op
  (local-first) implementation that reports no entitlement. The presentation
  layer depends only on the port; the SDK stays in data/composition.
- Entitlement state (`isPro`) is exposed reactively; RevenueCat is identified
  with the Firebase uid (`logIn`/`logOut`) so Pro follows the account across
  devices, linking into the existing auth flow.
- A paywall screen/Cubit driven by RevenueCat offerings; gating points: adding a
  second pet, and entering Smart Input / document scanning. Existing data is
  grandfathered (gates apply to new actions, never hide saved records).
- Store/dashboard configuration (RevenueCat entitlement/offering, App Store
  Connect + Play Console subscription products, public SDK keys) is tracked as
  setup tasks; the code is built behind the port and testable with the no-op.
- Reuse the analytics port to log paywall and purchase events. No personal or
  medical data is sent to RevenueCat — only the uid.
