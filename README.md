# PawVault

PawVault is a Flutter app for managing a pet health archive. It stores pet
profiles, health events, documents, reminders, AI-structured notes, scanned
documents, and vet summary exports, backed by Firebase.

## Features

- **Pets** — create, edit, and delete pet profiles (species, breed, weight,
  allergies, conditions, notes).
- **Health timeline** — log events (vaccinations, vet visits, medications, …)
  with type/date filtering.
- **Documents** — upload passports, lab results, and insurance (image/PDF) to
  storage with metadata, expiry tracking, and delete.
- **Smart text input (Gemini)** — turn free text into a structured draft you
  review and confirm before anything is saved.
- **Document scanning (Gemini)** — photograph or pick a document; the AI reads
  it and pre-fills an editable form that saves into the pet's documents.
- **Reminders** — schedule reminders with repeat rules and local notifications;
  mark complete or delete.
- **Vet summary export** — generate a PDF of the pet's records, share it, and
  optionally save a copy.
- **Accounts** — works anonymously by default; sign in with email, Google, or
  Apple to back up and sync, linking existing data to the account.

AI never writes to Firestore directly — it only produces drafts that require
explicit user confirmation.

## Stack

- Flutter
- Dart
- Bloc/Cubit
- AutoRoute
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Firebase AI Logic / Gemini
- Firestore offline persistence
- Feature-based architecture

## Setup

Install dependencies:

```bash
flutter pub get
```

Generate code after route or generator changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run the app:

```bash
flutter run
```

Run with Firebase-ready dependencies:

```bash
flutter run --dart-define=PAWVAULT_USE_FIREBASE=true
```

Without that flag, the app starts in local-first placeholder mode and does not
initialize Firebase.

Run required checks:

```bash
dart format .
flutter analyze
flutter test
```

## Firebase Setup Notes

Firebase-ready dependencies and generated platform files are present for:

- Firebase Core
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Firebase AI Logic / Gemini

Account sign-in (email/Google/Apple) requires extra provider and platform
configuration — see `docs/AUTH_SETUP.md`. The app works anonymously without it.

Firebase SDK access stays behind data sources and repositories — UI and Cubits
do not call Firebase SDKs directly.

Gemini only structures user-provided data into drafts or suggested actions. It
does not write directly to Firestore. Every AI-generated action is shown to the
user for confirmation before saving.

## Documentation

- `docs/NAVIGATION.md` — every screen and how to reach it, plus how to verify
  flows against a running app via the Dart/Flutter MCP server.
- `docs/AUTH_SETUP.md` — Firebase/Google/Apple configuration for account
  sign-in.
- `docs/PLATFORM_CONFIG.md` — app metadata, identifiers, icons, SDK levels, and
  permissions, with release gaps.
- `docs/CICD.md` — GitHub Actions → TestFlight deployment and the required
  App Store Connect API key secrets.
- `.ai/ROADMAP.md` and `.ai/TASKS.md` — the phased build plan (all phases
  complete) and task history.

## Development Workflow

Before coding, read:

- `AGENTS.md`
- `.ai/ROADMAP.md`
- `.ai/TASKS.md`
- `.ai/PLANS.md`

Then:

1. Pick the first unchecked task in `.ai/TASKS.md`.
2. Implement only that task.
3. Mark it done.
4. Add follow-up tasks if needed.
5. Run `dart format .`, `flutter analyze`, and `flutter test`.

Do not skip roadmap phases or implement multiple large phases at once.

See `docs/NAVIGATION.md` for the full screen-to-screen navigation map.

## Dart/Flutter MCP Server

The Dart/Flutter MCP server lets an AI agent analyze the project and inspect a
running app (runtime errors, widget tree, hot reload).

Add it once per tool:

```bash
# Claude Code
claude mcp add --transport stdio dart -- dart mcp-server
```

```toml
# Codex (.codex/config.toml or ~/.codex/config.toml)
[mcp_servers.dart]
command = "dart"
args = ["mcp-server"]
```

MCP tools load at session start, so start a new session after adding it.

To inspect a running app, connect to its Dart Tooling Daemon (DTD): list the
available DTD URIs, connect to the one whose workspace root is this project,
then use `get_runtime_errors`, `widget_inspector`, and `hot_reload`. See
`AGENTS.md` → MCP for the full tool list and workflow.

## Continuing With Codex

Ask Codex to continue from the autonomous workflow:

```text
Read AGENTS.md, .ai/ROADMAP.md, .ai/TASKS.md, and .ai/PLANS.md.
Pick the first unchecked task and implement only that task.
Run the required checks and update .ai/TASKS.md.
```

Preferred Dart/Flutter MCP server config:

```toml
[mcp_servers.dart]
command = "dart"
args = ["mcp-server"]
```

This project includes `.codex/config.toml` with that MCP block. If project-level
Codex config is not supported by the local installation, add the same block to
the global Codex config at `$CODEX_HOME/config.toml` or `~/.codex/config.toml`.

In this environment the Dart MCP server is available, but Codex does not expose
whether it came from project config or global/session config. If a future
session starts without Dart/Flutter MCP tools, install the block globally and
restart Codex from this project root.
