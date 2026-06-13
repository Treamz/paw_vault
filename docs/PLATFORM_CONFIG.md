# Platform Configuration Review

Status of app metadata, identifiers, icons, SDK levels, and permissions, with
gaps to address before a store release.

## Fixed in this pass

- **Android `INTERNET` permission** — added to the main manifest. It was only in
  the debug/profile manifests, so release builds would have lacked network
  access (breaking Firebase).
- **Android display label** — set to `PawVault` (was `paw_vault`).

## Current state

| Item | iOS | Android |
| --- | --- | --- |
| Display name | `Paw Vault` (CFBundleDisplayName) | `PawVault` |
| App / bundle id | `com.treamz.pawVault` | `com.example.paw_vault` |
| Min SDK / deployment target | iOS 15.0 | `flutter.minSdkVersion` |
| Launcher icon | default Flutter icon | default Flutter icon |
| Permissions | Camera, Photo Library | INTERNET (+ plugin-injected) |

iOS camera/photo usage strings exist for the document-scan flow. Google/Apple
sign-in need no extra iOS permission strings (Google uses the URL scheme, Apple
uses the entitlement).

## Gaps to address before release

- **Android application id** is still `com.example.paw_vault`. It matches the
  Android entry in `google-services.json`, so it works today, but should be
  rebranded (e.g. `com.treamz.pawvault`) for release. Changing it requires
  re-registering the Android app in Firebase and downloading a new
  `google-services.json`.
- **Launcher icons are the default Flutter icon.** Add a branded PawVault icon
  (e.g. via the `flutter_launcher_icons` package) for iOS and Android.
- **`RunnerTests` bundle id** is still `com.example.pawVault.RunnerTests`
  (cosmetic; does not affect the app).

## Sign-in provider configuration

Account sign-in (email/Google/Apple) also needs Firebase/Apple/Google setup —
see `docs/AUTH_SETUP.md`.
