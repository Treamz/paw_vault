# Phase 3 Firebase Startup

## Scope

Added a startup path that initializes Firebase only when Firebase-ready
dependencies are selected. This does not configure Firestore offline
persistence, anonymous auth bootstrap, or Firebase repository implementations.

## Runtime Modes

Default startup:

```bash
flutter run
```

Uses:

```dart
AppDependencies.localFirst()
```

Firebase-ready startup:

```bash
flutter run --dart-define=PAWVAULT_USE_FIREBASE=true
```

Uses:

```dart
FirebaseAppInitializer.initialize()
AppDependencies.firebaseReady(FirebaseInstances())
```

## Boundary

Firebase initialization is isolated in `AppBootstrap.createDependencies`.
Widgets and Cubits still receive repositories through `PawVaultApp` and do not
access Firebase SDKs directly.
