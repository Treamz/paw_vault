# Release Readiness

Result of the Phase 12 final checks (2026-06-13).

## Automated checks — PASS

- `dart format .` — clean (no changes).
- `flutter analyze` — no issues (with the tightened lint set).
- `flutter test` — **298 tests pass**.

## Live smoke — PASS

Verified on an iPhone 17 Pro simulator in Firebase mode during development:
pet create/list/profile, document scan with Gemini extraction → save to Storage,
reminders, smart input, vet summary generation, and account sign-in/out with
anonymous-to-account linking.

## Known issues / notes

- **Debug-only framework assertion:** `SystemContextMenu: Attempted to show
  while another instance was still visible` can appear when interacting with
  text fields on iOS. It originates in the Flutter framework (not app code),
  only fires in **debug** builds (assertions are stripped in profile/release),
  and was amplified by the Flutter Driver text-input emulation used during
  testing. Not a release blocker.
- **Sign-in providers** must be enabled in the Firebase console and configured
  per `docs/AUTH_SETUP.md`; the app works anonymously without this.

## Before public store release

See `docs/PLATFORM_CONFIG.md` for details:

- Rebrand the Android application id off `com.example.paw_vault` (requires
  re-registering the Android app in Firebase).
- Add a branded launcher icon (iOS + Android).
- Bump the iOS deployment target if a release build requires it for Firebase
  pods.

## Verdict

**Ready for internal/beta testing.** Address the platform-config items above
(app id, icon, deployment target) before a public store submission.
