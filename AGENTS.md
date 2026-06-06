# AGENTS.md

## Project

PawVault is a Flutter mobile app for storing a pet’s health archive.

## Tech Stack

- Flutter
- Dart
- Bloc/Cubit
- AutoRoute
- Local-first MVP
- No backend for MVP

## Rules

- Use feature-based architecture.
- Do not add Firebase or Supabase.
- Do not implement real medical advice.
- AI features must only structure user-provided data.
- Always show confirmation before saving AI-parsed data.
- Do not put business logic inside widgets.
- Prefer Cubit for simple flows.
- Use repositories between UI and data sources.
- Keep features isolated.

## Required checks

Before finishing any task, run:

```bash
dart format .
flutter analyze
flutter test
