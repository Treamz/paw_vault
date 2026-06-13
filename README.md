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
