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

## Phase 9: Reminders and local notifications

Implement reminders, repeat rules, completion state, and local notifications.

## Phase 10: Vet summary PDF export

Implement vet summary PDF generation, local sharing/export, and optional
Firebase Storage upload.

## Phase 11: Polish, tests, release candidate

Improve UX, accessibility, error states, empty states, test coverage, platform
configuration, and release readiness.
