# AGENTS.md

## Project

PawVault is a Flutter mobile app for pet health archive management.

The app stores and organizes pet profiles, health timeline events, documents,
reminders, smart text input, document extraction drafts, and vet summary
exports.

## Tech Stack

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

## Durable Rules

- Use feature-based architecture.
- Use Bloc/Cubit for presentation state.
- Prefer Cubit for simple flows.
- Use repositories between UI and Firebase/data sources.
- Keep features isolated.
- Do not put business logic inside widgets.
- Do not let widgets access Firebase SDKs directly.
- Do not let Gemini write directly to Firestore.
- Gemini must only return draft or suggested structured data.
- Every AI action must require user confirmation before saving.
- AI features must only structure user-provided data.
- Do not provide medical diagnosis or treatment advice.
- Do not position PawVault as a replacement for a veterinarian.
- Do not add Supabase.

## Autonomous Workflow

Before coding:

- Read `AGENTS.md`.
- Read `.ai/ROADMAP.md`.
- Read `.ai/TASKS.md`.
- Inspect the relevant project structure.
- Check Dart/Flutter diagnostics when the change is substantial.
- Check `pubspec.yaml` before dependency or architecture changes.

During coding:

- Pick the first unchecked task in `.ai/TASKS.md`.
- Implement only that task.
- Do not skip roadmap phases.
- Do not implement multiple large phases at once.
- Add follow-up tasks if new work is discovered.
- Mark completed tasks in `.ai/TASKS.md`.

Stop only when credentials, Firebase console actions, account setup, product
decisions, or other human decisions are required.

## Git Workflow

- Keep one branch focused on one roadmap phase or tightly related feature area.
- Create a new branch when starting a new roadmap phase, a materially different
  feature area, or work that should be reviewed separately.
- Stay on the current branch for small follow-up tasks within the same phase.
- Commit after a coherent task is complete, required checks pass, and
  `.ai/TASKS.md` is updated.
- Do not commit half-finished behavior unless the user explicitly asks for a
  checkpoint commit.
- Before switching branches, commit or intentionally carry only related
  uncommitted changes.
- Never switch branches with unrelated dirty work without first clarifying with
  the user.
- Use short imperative commit messages, for example `Start pet CRUD list flow`.

## MCP

Use the Dart and Flutter MCP server when available.

### Setup

Claude Code (CLI):

```bash
claude mcp add --transport stdio dart -- dart mcp-server
```

Codex (`.codex/config.toml` or `~/.codex/config.toml`):

```toml
[mcp_servers.dart]
command = "dart"
args = ["mcp-server"]
```

MCP tools load at session start; after adding the server, start a new session.

### Working with it

Static analysis without a running app:

- `analyze_files` — analyze the project or specific paths for errors.
- `pub_dev_search`, `pub` — discover/manage packages.
- `read_package_uris`, `rip_grep_packages` — explore dependency source (e.g. to
  check a package's real API before using it).

Inspecting a running app (requires a DTD connection):

1. `dtd` → `listDtdUris` to find the running app's daemon, then `dtd` →
   `connect` with the URI whose workspace root is this project.
2. `get_runtime_errors` — read the most recent runtime errors (e.g. layout
   overflows, exceptions). Use this to diagnose UI bugs reported by the user.
3. `widget_inspector` (`get_widget_tree`, `summaryOnly: true`) — inspect the
   live widget tree to confirm which screen is shown and that expected widgets
   render.
4. `hot_reload` — apply code changes to the running app, then re-check
   `get_runtime_errors` to confirm the fix.

`flutter_driver_command` (tap/enter_text/screenshot) requires the app to be
launched with `enableFlutterDriverExtension()`; it is not available on a normal
`flutter run`. Without it, verify by inspecting the widget tree and watching
`get_runtime_errors`.

See `docs/NAVIGATION.md` for the screen-to-screen flow used when verifying UI.

## Required Checks

Before finishing any task, run:

```bash
dart format .
flutter analyze
flutter test
```
