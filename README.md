# PawVault

PawVault is a Flutter app for managing a pet health archive. It is designed to
store pet profiles, health events, documents, reminders, smart text input
drafts, document extraction drafts, and vet summary exports.

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

The app currently keeps feature behavior placeholder-first. Firebase SDK access
should stay behind data sources and repositories. UI and Cubits must not call
Firebase SDKs directly.

Gemini must only structure user-provided data into drafts or suggested actions.
It must not write directly to Firestore. Every AI-generated action must be
shown to the user for confirmation before saving.

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
