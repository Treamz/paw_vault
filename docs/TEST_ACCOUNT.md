# Test account with sample data

How to get a PawVault account populated with realistic data for manual
testing, demos, and screenshots.

There is **no shared test account and no credentials in this repository**, by
design — a password in git history is a password you can never take back. You
create the account yourself; the app fills it with data.

## One-time: create the account

Run the app, open the account screen from the pet list, and sign up with
whatever email and password you want to use for testing. Any email works; it
does not have to be real, because PawVault never sends mail to it.

Keep those credentials in your password manager, not in the repo.

## Fill it with data

```bash
flutter run \
  --dart-define=PAWVAULT_USE_FIREBASE=true \
  --dart-define=PAWVAULT_SEED=true
```

Sign in as your test user. `DevSeeder` notices the account has no pets and
writes the full sample set:

| What | Contents |
|---|---|
| Pets | Bella (golden retriever) and Max (cat) |
| Timeline | vaccinations, a vet visit, medication, grooming |
| Documents | rabies certificate, insurance policy, blood panel |
| Reminders | booster due, flea & tick, annual exam |
| Smart Input | three past analyses in the history |
| Paw Scan | two checks of the same paw, 12 days apart |
| Weight | four measurements, a gentle upward trend |

Then **remove the seed flag** for subsequent runs. Leaving it on is harmless —
seeding skips an account that already has pets — but dropping it keeps launches
quick and avoids surprises.

## How the safety rails work

- **Debug builds only.** `DevSeeder.isEnabled` is `kDebugMode && PAWVAULT_SEED`,
  so a release build ignores the flag even if it is left in a CI command.
- **Idempotent.** `seedIfEmpty` skips any account that already has pets, so it
  will not duplicate records or overwrite data you entered by hand.
- **Follows sign-in, not launch.** Seeding listens to the auth stream rather
  than running once at startup. The app starts anonymous, and signing into an
  account that already exists produces a *different* uid — a one-shot seed at
  launch would fill the anonymous account and leave the one you logged into
  empty.
- **Goes through repositories**, never Firebase directly, so it obeys the same
  invariants as the app: only confirmed smart messages and confirmed paw checks
  are written, because the repositories reject anything else.

## Getting Pro (needed for Smart Input and Paw Scan)

Both AI features are gated behind Pro. The quickest way in during development
is to run **without** RevenueCat keys: with no `REVENUECAT_IOS_API_KEY` /
`REVENUECAT_ANDROID_API_KEY`, `AppBootstrap` falls back to
`NoopSubscriptionService`, which reports `Entitlements.unlocked`. The command
above does exactly that, so Pro is already on.

To test the *real* purchase flow you need the App Store Connect subscription
products and the RevenueCat `pro` entitlement/offering to exist — still an open
item in `.ai/TASKS.md` (Phase 14). See `docs/MONETIZATION.md`.

## Known rough edges in the seeded data

- **Documents and exports point at `example.com`.** The metadata is real but
  the files are not, so opening a seeded document or export will fail. Upload a
  real file through the app if you need that path to work.
- **Paw checks have no photos.** `photoUrls` is empty, so the journal shows a
  placeholder and the before/after comparison has no images. Run a real scan to
  get photos.
- **Pets have no profile photo.** Add one through the app if you need it.

Filling these in would mean uploading real bytes to Storage during seeding,
which the seeder deliberately does not do — it writes metadata only.

## Local-first mode is not a substitute

`flutter run` without `PAWVAULT_USE_FIREBASE=true` skips Firebase entirely, and
the local repositories are empty stubs that accept writes and return nothing.
Seeding there does nothing visible. Local-first is for checking that the app
builds and navigates without Firebase, not for looking at data.
