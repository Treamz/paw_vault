# Phase 3 Anonymous Auth Bootstrap

## Scope

Added an anonymous authentication bootstrap contract for Firebase-ready startup.
This does not add UI auth flows, account linking, or Firebase repository
implementations.

## Behavior

When Firebase-ready startup is selected:

1. Firebase initializes.
2. Firestore offline persistence is configured.
3. Firebase-ready dependencies are created.
4. `AnonymousAuthBootstrap.ensureSignedIn(...)` checks the current auth user.
5. If no user exists, it calls `AuthRepository.signInAnonymously()`.

## Boundary

The bootstrap depends on `AuthRepository`, not on Firebase Auth directly. This
keeps Firebase SDK usage inside data sources and dependency setup.

## Tests

Added focused tests to confirm:

- existing users are reused;
- anonymous sign-in runs only when there is no current user.
