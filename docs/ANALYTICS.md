# Analytics

PawVault uses Google Analytics for Firebase, integrated behind an
`AnalyticsService` port (Phase 13). It is **disabled in local-first mode**
(`NoopAnalyticsService`) and only active in Firebase-ready builds
(`FirebaseAnalyticsService`). Widgets and Cubits depend on the port — never the
`firebase_analytics` SDK directly.

## Privacy

Only **non-identifying counts and types** are sent. No names, notes, document
text, or other personal/medical content is ever included as an event parameter.
The analytics user id is the (possibly anonymous) Firebase uid, set/cleared as
the auth state changes.

## What is tracked

### Apple Search Ads campaigns (not in `AnalyticsEvents`)

`firebase_campaign` is logged by the **native** Firebase SDK, not through
`AnalyticsService`, so you will not find it in `analytics_events.dart`.
GoogleAppMeasurement ships its own Apple Search Ads reporter
(`APMSearchAdReporter`) which reads the AdServices token, resolves it with
Apple, and logs `source = Apple`, `medium = search`, `campaign = <campaignId>`,
`term = <keywordId>` — populating GA4's standard acquisition dimensions.

It is enabled by `AdServices.framework` being loaded in the process; without
that the SDK logs *"AdServices framework is not linked. Search Ad Attribution
Reporter is disabled."* and does nothing. `RevenueCat.framework` already links
AdServices, so no build change was needed — see `docs/ASA.md` for the
verification command and the fragility that creates.

This keeps the privacy rule above structural rather than procedural: the
attribution token is an install identifier, and **no Dart code ever holds it**,
so there is no code path from a token to `logEvent`. See `docs/ASA.md`.

### Screen views
Automatic, via `AnalyticsRouteObserver` wired into the AutoRoute navigator. Each
route change logs a `screen_view` with the route name (e.g. `PetListRoute`).

### Product events
Logged from the owning Cubit on success (`lib/core/analytics/domain/services/analytics_events.dart`):

| Event | Params | Fired when |
| --- | --- | --- |
| `pet_created` | — | A new pet is saved |
| `timeline_event_added` | `type` (event type) | A health timeline event is created |
| `document_uploaded` | `type` (document type) | A document is uploaded/saved |
| `reminder_created` | — | A reminder is created |
| `smart_input_used` | — | Smart Input analyzes text into a draft |
| `vet_summary_exported` | — | A vet summary PDF is generated |
| `login` | `method` (`email`/`google`/`apple`) | An account sign-in succeeds |

`login` is Firebase's recommended sign-in event; `screen_view` and the user id
are standard automatic dimensions.

## Adding a new event

1. Add the name to `AnalyticsEvents` (and any keys to `AnalyticsParams`).
2. Inject `AnalyticsService` into the Cubit (optional param, defaults to
   `NoopAnalyticsService` so tests stay green) and pass
   `analytics: context.read<AnalyticsService>()` from the screen.
3. Call `_analytics.logEvent(AnalyticsEvents.x, parameters: {...})` on success.
   Send only non-identifying values.

## Viewing the data

Firebase Console → your project → **Analytics**:

- **Realtime** / **DebugView** — see events as they happen. Enable debug mode on
  a device first:
  - iOS: run with the launch arg `-FIRDebugEnabled`.
  - Android: `adb shell setprop debug.firebase.analytics.app com.treamz.paw_vault`.
- **Events** — counts per event over time; mark important ones as conversions.
- **Reports / Explore** — funnels and breakdowns (e.g. `document_uploaded` by
  `type`). Custom event parameters need to be registered as custom dimensions in
  Analytics before they appear in reports.

Data typically takes up to 24h to appear outside Realtime/DebugView.

## Notes

- New events/parameters may take a day to surface in standard reports; use
  DebugView to verify wiring immediately.
- Analytics is a no-op in local-first runs (`flutter run` without
  `--dart-define=PAWVAULT_USE_FIREBASE=true`), so nothing is collected during
  local development unless Firebase mode is enabled.
