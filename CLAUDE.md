# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PawVault is a Flutter mobile app for pet health archive management. It stores pet profiles, health timeline events, documents, reminders, smart text input drafts, document extraction drafts, and vet summary exports using Firebase services (Auth, Firestore, Storage, AI/Gemini).

## Development Commands

### Install Dependencies
```bash
flutter pub get
```

### Code Generation
Run after making changes to routes or any code using generators (like AutoRoute):
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Running the App
Local-first mode (placeholder data, no Firebase):
```bash
flutter run
```

Firebase-ready mode:
```bash
flutter run --dart-define=PAWVAULT_USE_FIREBASE=true
```

### Required Checks
Before finishing any task or committing, run all three:
```bash
dart format .
flutter analyze
flutter test
```

### Running Tests
All tests:
```bash
flutter test
```

Single test file:
```bash
flutter test test/path/to/file_test.dart
```

## Architecture

### Feature-Based Structure
The codebase uses feature-based architecture with strict separation of concerns:

```
lib/
├── app/                    # App initialization, routing, theme
│   ├── bootstrap/         # Dependency injection setup
│   ├── router/            # AutoRoute configuration
│   └── theme/             # Light/dark theme
├── core/                   # Shared infrastructure
│   ├── auth/              # Firebase Auth abstraction
│   ├── storage/           # Firebase Storage abstraction
│   ├── firebase/          # Firebase initialization, paths, mappers
│   └── di/                # AppDependencies factory
└── features/               # Domain features (pets, timeline, etc.)
    └── <feature>/
        ├── data/          # Repositories, data sources, mappers
        ├── domain/        # Entities, repositories (interfaces), value objects
        └── presentation/  # Cubits, screens, widgets
```

### Dependency Injection Pattern
The app uses two bootstrap modes controlled via `AppDependencies`:

- **`AppDependencies.localFirst()`**: Uses noop/local implementations, no Firebase initialization
- **`AppDependencies.firebaseReady(FirebaseInstances)`**: Uses real Firebase data sources

The bootstrap decision happens in `app_bootstrap.dart` based on the `PAWVAULT_USE_FIREBASE` compile-time flag.

### Data Flow
1. **UI (screens/widgets)** → call methods on **Cubits**
2. **Cubits** → call methods on **Repository interfaces** (domain layer)
3. **Repositories** → call **Data Sources** (Firestore, Storage, Auth, AI)
4. **Data Sources** → interact with Firebase SDKs
5. **Mappers** handle conversion between domain entities and Firestore documents

**Critical constraints:**
- UI widgets must never access Firebase SDKs directly
- Cubits must never access Firebase SDKs directly
- All Firebase access must go through data sources and repositories
- Gemini AI must never write directly to Firestore; it only returns draft/suggested data that requires user confirmation

### State Management
- Uses **flutter_bloc** (Bloc/Cubit)
- Prefer **Cubit** for simple flows
- Use **Bloc** for complex event-driven flows
- No business logic in widgets

### Routing
- Uses **AutoRoute** for declarative routing
- Router config in `lib/app/router/`
- After route changes, regenerate with `dart run build_runner build --delete-conflicting-outputs`

### Firebase Integration
- **Auth**: Anonymous authentication bootstrap on Firebase-ready mode
- **Firestore**: Offline persistence enabled in Firebase-ready mode
- **Storage**: Document/photo uploads with path helpers in `lib/core/firebase/storage/`
- **AI (Gemini)**: Smart text input and document extraction (draft-only, requires user confirmation)
- **Mappers**: All Firestore mappers in `lib/features/<feature>/data/mappers/` with round-trip tests
- **Paths**: Firestore collection/document paths in `lib/core/firebase/firestore/firestore_paths.dart`

## Workflow Rules

### Before Coding
Read in order:
1. `AGENTS.md` - Durable rules and workflows
2. `.ai/ROADMAP.md` - Phased roadmap
3. `.ai/TASKS.md` - Current task checklist
4. `.ai/PLANS.md` - Implementation plans (if applicable)

### During Coding
- Pick the **first unchecked task** in `.ai/TASKS.md`
- Implement **only that task**
- Do not skip roadmap phases
- Do not implement multiple large phases at once
- Add follow-up tasks if new work is discovered
- Mark completed tasks in `.ai/TASKS.md`

### Git Workflow
- Keep one branch focused on one roadmap phase or tightly related feature area
- Create new branch when starting new roadmap phase or materially different feature
- Stay on current branch for small follow-up tasks within the same phase
- Commit after coherent task completion and required checks pass
- Never commit half-finished behavior unless explicitly requested
- Use short imperative commit messages (e.g., "Start pet CRUD list flow")
- Before switching branches, commit or clarify with user about dirty work

### AI/Medical Safety Constraints
- Do not provide medical diagnosis or treatment advice
- Do not position PawVault as a replacement for a veterinarian
- Gemini must only structure user-provided data into drafts or suggested actions
- Every AI-generated action must be shown to user for confirmation before saving
- AI features must not write directly to Firestore

### Technology Constraints
- Do not add Supabase
- Use Flutter, Dart, Bloc/Cubit, AutoRoute, Firebase stack only

## MCP Server

Preferred Dart/Flutter MCP server configuration:

```toml
[mcp_servers.dart]
command = "dart"
args = ["mcp-server"]
```

Add to global Codex config at `~/.codex/config.toml` or `$CODEX_HOME/config.toml` if project-level config is not supported.

When the Dart MCP server is available, use Flutter MCP tools to inspect runtime errors and widget tree when the app is running.
