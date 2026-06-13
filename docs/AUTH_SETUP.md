# Account Auth Setup (Email, Google, Apple)

The account-auth code (email/password, Google, Apple, with anonymous→permanent
linking) is implemented behind `AccountAuthRepository`. The sign-in methods only
work on-device once the provider/platform configuration below is done. The app
keeps working anonymously without any of this.

## 1. Firebase Console — enable providers

Firebase Console → your project → **Authentication → Sign-in method**, enable:

- **Email/Password**
- **Google** (set a project support email)
- **Apple**

Anonymous is already enabled (used for the local-first bootstrap).

## 2. Email/password

No client configuration beyond enabling the provider. `registerWithEmail` links
the email credential to the current anonymous user; if the email is already
registered it falls back to signing in.

## 3. Google sign-in (`google_sign_in`)

### iOS
- Ensure `ios/Runner/GoogleService-Info.plist` is present (from Firebase) — it
  contains `CLIENT_ID` and `REVERSED_CLIENT_ID`.
- Add the `REVERSED_CLIENT_ID` as a URL scheme in `ios/Runner/Info.plist`:

  ```xml
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>com.googleusercontent.apps.XXXXXXXX-XXXXXXXX</string>
      </array>
    </dict>
  </array>
  ```

### Android
- Add the app's SHA-1 (and SHA-256) signing fingerprints in Firebase project
  settings, then download the updated `google-services.json` into
  `android/app/`.

## 4. Sign in with Apple (`sign_in_with_apple`)

### Apple Developer
- Enable the **Sign in with Apple** capability on the App ID.
- For non-iOS flows (Android/web), create a **Services ID** and a **Sign in with
  Apple key**; note the Team ID, Key ID, and private key.

### Xcode
- In the Runner target → **Signing & Capabilities**, add the **Sign in with
  Apple** capability (this writes the entitlement).

### Firebase
- In the Apple provider config, fill in the **Services ID**, **Apple Team ID**,
  **Key ID**, and **private key**.

The app generates a nonce and sends its SHA-256 hash to Apple, passing the raw
nonce to Firebase (replay protection) — this is handled in code.

## 5. Verify

Run with Firebase enabled:

```bash
flutter run --dart-define=PAWVAULT_USE_FIREBASE=true -d <device>
```

Open the account action (person icon, top-right of the pet list) → sign up with
email, or use Google/Apple. Existing anonymous data should carry over after the
first sign-up (account linking).
