# Monetization (RevenueCat)

PawVault Pro is sold via RevenueCat (`purchases_flutter`), behind a
`SubscriptionService` port. The local-first build uses a no-op implementation
that grants full access (there is no store); the Firebase-ready build uses
RevenueCat when an API key is provided.

## The model

| | Free | **Pro** |
| --- | --- | --- |
| Pets | 1 | Unlimited |
| Smart Input (AI) | — | ✓ |
| Document scanning (AI) | — | ✓ |
| Timeline, documents, reminders, vet PDF | ✓ | ✓ |

Plan: an **annual** auto-renewable subscription with a **free trial** (intro
offer). Existing data is grandfathered — gates only block *new* premium actions.

## Architecture

- `SubscriptionService` (domain port) → `RevenueCatSubscriptionService` (data) /
  `NoopSubscriptionService` (local-first). Presentation never imports the SDK.
- `SubscriptionCubit` exposes `isPro` reactively (app-level provider).
- Gates: `core/subscription/presentation/pro_gate.dart` (`showPaywall`,
  `kFreePetLimit`). The pet-list "Add pet" FAB and the pet-profile "Smart Input"
  entry call it; document scanning is reached only through Smart Input.
- Identity: `AccountCubit` calls `identify(uid)` / `resetIdentity()` so Pro
  follows the Firebase account across devices.
- Paywall: **designed in the RevenueCat dashboard** (not hard-coded). Presented
  via a `PaywallPresenter` port → `RevenueCatPaywallPresenter`
  (`purchases_ui_flutter` / `RevenueCatUI.presentPaywallIfNeeded('pro')`) /
  `NoopPaywallPresenter` (local-first). `showPaywall` calls it and logs
  `paywall_viewed`, `purchase_completed`, `purchase_restored` analytics events.

## API keys (code-side)

RevenueCat **public SDK keys** are read at bootstrap via dart-define:

```bash
flutter run --dart-define=PAWVAULT_USE_FIREBASE=true \
  --dart-define=REVENUECAT_IOS_API_KEY=appl_xxx \
  --dart-define=REVENUECAT_ANDROID_API_KEY=goog_xxx
```

If no key is provided, the app falls back to the no-op service (everything
unlocked) so it still runs. Add the keys to the CI workflow's build step for
TestFlight.

## One-time setup (console-side — required before real purchases work)

1. **App Store Connect** → create an **auto-renewable subscription group** + a
   product (e.g. `pawvault_pro_annual`), and add a **free trial** introductory
   offer. (Play Console equivalents for Android.)
2. **RevenueCat dashboard:**
   - Add the app(s) and the public SDK key(s).
   - Create an **entitlement** with identifier **`pro`** (must match
     `RevenueCatSubscriptionService.entitlementId`).
   - Add the store product and attach it to the `pro` entitlement.
   - Create an **offering** (the default one) containing the annual package.
   - **Design a Paywall** for that offering (RevenueCat → Paywalls). This is the
     UI the app shows — the app does not ship a hard-coded paywall. Add your
     Terms of Use and Privacy Policy links there
     (https://pawvault-e0cc5.web.app/terms and `/privacy`).
3. Add the SDK keys as dart-defines / CI secrets.

## Testing

- iOS: create a **StoreKit configuration file** in Xcode for local testing, or
  use a **sandbox tester** account. The dashboard paywall is presented by
  RevenueCatUI; Pro unlocks immediately after a sandbox purchase, and the
  paywall's built-in **Restore** re-syncs.
- The no-op services make local-first runs and all unit tests behave as Pro;
  the subscription/presenter logic is covered by unit tests with fakes.

## Notes

- Only the Firebase uid is sent to RevenueCat — no personal or medical data.
- `entitlementId` defaults to `pro`; change it in one place if the dashboard
  uses a different identifier.
