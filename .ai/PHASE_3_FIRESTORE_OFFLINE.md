# Phase 3 Firestore Offline Persistence

## Scope

Configured Firestore offline persistence in the Firebase startup path only.
Local-first startup remains unchanged and does not initialize Firebase.

## Behavior

When Firebase-ready mode is selected:

```bash
flutter run --dart-define=PAWVAULT_USE_FIREBASE=true
```

Startup now performs:

1. Firebase app initialization.
2. Firebase instance creation.
3. Firestore offline settings configuration.
4. Firebase-ready dependency construction.

## Firestore Settings

Configured settings:

- `persistenceEnabled: true`
- `cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED`

These settings are applied before repositories are constructed and before app
code should access Firestore collections.

## Boundary

The configuration lives in:

```text
lib/core/firebase/firestore/firestore_offline_configurator.dart
```

Widgets and Cubits still do not access Firebase SDKs directly.
