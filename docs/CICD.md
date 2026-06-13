# CI/CD — TestFlight deployment

PawVault ships to TestFlight from GitHub Actions
(`.github/workflows/testflight.yml`). The workflow runs the tests, builds the
iOS app, signs it with **App Store Connect automatic (cloud) signing**, and
uploads it via fastlane. No certificates or provisioning profiles are stored in
the repo or in CI — Xcode requests them from App Store Connect at build time
using an API key.

## When it runs

- **On a version tag:** push a tag like `v1.0.0` → the marketing version is
  taken from the tag (`1.0.0`).
- **Manually:** Actions tab → *TestFlight* → *Run workflow*. You may type a
  marketing version; otherwise it defaults to `1.0.0`.

The build number (`CFBundleVersion`) is the GitHub Actions run number, which
increases on every run so TestFlight always receives a unique, higher build.

## One-time setup

### 1. App Store Connect record

The app must exist in App Store Connect with bundle id **`com.treamz.pawVault`**
(team `64QDKH3589`). Create it under *Apps → +* if it doesn't exist, and accept
any pending agreements in *Business* / *Agreements*.

### 2. Create an App Store Connect API key

App Store Connect → **Users and Access → Integrations → App Store Connect API**
→ generate a **Team key** with the **App Manager** role (needed so it can manage
signing assets and upload builds). Download the `.p8` file (you can only
download it once) and note the **Key ID** and **Issuer ID**.

### 3. Add the repository secrets

GitHub → repo → *Settings → Secrets and variables → Actions → New repository
secret*:

| Secret            | Value                                                            |
| ----------------- | --------------------------------------------------------------- |
| `ASC_KEY_ID`      | The key's Key ID (e.g. `ABC123XYZ9`).                            |
| `ASC_ISSUER_ID`   | The Issuer ID (a UUID, shown above the keys list).              |
| `ASC_KEY_CONTENT` | The `.p8` file contents, **base64-encoded** (see below).        |

Encode the key:

```bash
base64 -i AuthKey_ABC123XYZ9.p8 | pbcopy   # macOS: copies the value to paste
```

The Fastfile reads it with `is_key_content_base64: true`, so paste the base64
string directly as the secret value.

## Triggering a release

```bash
# bump the version in pubspec.yaml first if desired, commit, then:
git tag v1.0.0
git push origin v1.0.0
```

Watch progress in the Actions tab. On success the build appears in TestFlight
after Apple finishes processing (a few minutes); add it to a test group there.

## Local dry run

From `ios/` with the three env vars exported:

```bash
cd ios
bundle install
flutter build ios --release --no-codesign   # run from repo root
ASC_KEY_ID=... ASC_ISSUER_ID=... ASC_KEY_CONTENT=$(base64 -i AuthKey.p8) \
  bundle exec fastlane beta
```

## Notes & limitations

- This pipeline covers **iOS / TestFlight** only. Android (Play Console) is not
  wired up; the Android application id is still `com.example.paw_vault`
  (see `docs/PLATFORM_CONFIG.md`).
- Automatic signing needs the API key role to be **App Manager** or **Admin**;
  a plain *Developer* key cannot create signing assets.
- The first run on a brand-new bundle id may take longer while App Store Connect
  provisions the signing certificate and profile.
