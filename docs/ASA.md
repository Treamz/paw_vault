# PawVault — Apple Search Ads

Campaign plan for paid acquisition on the App Store. Console work happens in the
[Apple Search Ads dashboard](https://searchads.apple.com); this document is what
to enter and why.

Companion to `docs/ASO.md`, which holds the keyword research these campaigns are
built on. The two feed each other: ads buy the search-term data that ASO §9 asks
for, and ASO decides which terms are worth buying.

## App

| | |
|---|---|
| App Store id | `6779953779` |
| Bundle | `com.treamz.pawVault` |
| Listing | PawVault: Pet Health Records |
| Live since | 2026-06-24 |
| Store version | 1.0.8 (1.0.9 in TestFlight at time of writing) |
| Ratings | 5.0 from 8 reviews |

Apple Search Ads requires a live app, so this is unblocked.

## Budget

**$10/day, United States, iOS.** Deliberately small: enough to get a signal in
about two weeks, cheap enough that a wrong read costs little.

| Campaign | Daily | State |
|---|---|---|
| Brand | ~$3 | on |
| Exact | ~$7 | on |
| Competitor | — | documented, off |
| Discovery | — | documented, off |

US only because every difficulty and traffic score in `docs/ASO.md` was measured
on the iOS US store. Running elsewhere means advertising against research that
does not apply.

---

## Campaign 1 — Brand (~$3/day)

Exact match: `pawvault`, `paw vault`, plus misspellings (`paw valut`,
`pawvalut`, `paw vault app`).

**This is defensive, not vanity.** Searching "PawVault" on the US App Store
returns four other apps carrying the name:

- PawVault: Dog Health Manager (SAVITAR GLOBAL)
- PawVault: Pet Health Tracker (Muhammad Haseeb Arshad)
- Paw Vault AI: Track Pet Health (Junaid Khan)
- PawPrint Vault (ChangChi Chu)

The term scores **difficulty 6.71 / traffic 8.34** — high traffic on a name you
do not own, with four exact title matches competing for it. Someone searching
your name can currently be shown someone else's app. A brand campaign is the
only way to sit above that reliably.

It is also the cheapest read on whether ads work at all: brand terms have the
lowest cost-per-tap and the highest conversion, so if the brand campaign cannot
convert, nothing further up the funnel will.

Start bids low. Brand terms rarely need much, and there is little competition
for the exact string beyond the squatters.

---

## Campaign 2 — Exact (~$7/day)

Exact match, one ad group, seeded straight from the scores in `docs/ASO.md`:

| Keyword | Difficulty | Traffic | Why this one |
|---|---|---|---|
| `vet records` | 6.49 | 7.0 | best ratio in the research; few competitors own it |
| `dog health` | 6.62 | 7.2 | easy and high traffic; competitors lead with "pet", not "dog" |
| `pet vaccine tracker` | 7.29 | 6.6 | matches the subtitle, so the page reads as a direct answer |
| `pet medical history` | 7.39 | 7.1 | high traffic, clear intent |
| `vaccine reminder` | 7.46 | 7.2 | high traffic; reminders are a real feature, not a stretch |

**Excluded on purpose at this budget:**

- `pet passport` — traffic 8.4, the highest available, but also the hardest.
  At $7/day it would absorb the whole budget for a handful of taps.
- `pet health tracker` — hardest with lower traffic; `docs/ASO.md` already
  marks it "avoid".
- `pet health record` — highest traffic (7.5) but harder (7.70). Worth adding
  second, once the cheaper terms have shown a conversion rate to compare
  against.

Add the brand terms as **negative keywords** here, so brand searches stay in the
brand campaign where they are cheaper and the reporting stays clean.

---

## Campaign 3 — Competitor (off at this budget)

Exact match on competitor names, from the read in `docs/ASO.md`: VitusVet,
VetVault, Wagly, Hubert, Mochii, MyLovet, PetFit.

Expect a worse conversion rate — someone searching a specific app usually wants
that app. Turn this on only once Brand and Exact have a known cost per install
to compare against, otherwise there is no way to tell whether it is bad.

## Campaign 4 — Discovery (off at this budget)

Search Match on, no keywords, with every term already bought in Brand and Exact
added as negatives. Its job is not conversion but **harvesting**: finding queries
the research missed.

Winners graduate: move a term that converts into the Exact campaign, then add it
as a negative in Discovery so the two stop bidding against each other.

---

## Before scaling spend

**The product page converts the ad, not the ad itself.** Two things to fix
before increasing budget, because both cap conversion no matter how good the
targeting is:

1. **8 reviews is thin social proof.** An ad tap lands on a page with eight
   ratings, and that is what the visitor judges. Volume of ratings also feeds
   organic ranking. `docs/ASO.md` §9 already recommends an in-app prompt after a
   natural success moment (for example a first vet-summary export); there is a
   task for it in `.ai/TASKS.md`. Getting ratings up is likely worth more per
   dollar than any bid change.
2. **The live listing does not mention Paw Scan.** The description still
   describes the AI features as "Smart Input and document scanning". Update the
   listing when 1.0.9 is released, or ads will promise less than the app
   actually does.

## How attribution works

Both SDKs the app already ships implement Apple Search Ads attribution
natively. The integration is therefore an *enablement*, not an implementation:

| Piece | Who does it |
|---|---|
| Read the AdServices token | RevenueCat (`AttributionFetcher.swift`) and Firebase (`APMSearchAdReporter`) |
| Resolve it with Apple | RevenueCat server-side; Firebase on-device |
| Retry while Apple is not ready | both, natively, with persisted state |
| Report at most once per install | both, natively |

Our code is **one port** (`lib/core/attribution/`). It has a RevenueCat
implementation calling `Purchases.enableAdServicesAttributionTokenCollection()`
— collection is opt-in, and `Purchases.configure` does not turn it on.

### What is on today, and what is not

| Half | State | Why |
|---|---|---|
| **Firebase → GA4 campaign attribution** | **on** | Works with no account, no plan, and no code of ours |
| **RevenueCat → revenue by campaign** | **off** | Needs RevenueCat's Apple Search Ads integration, which is a paid-plan feature |

RevenueCat's Apple Search Ads integration is not on the free plan, so
`AppBootstrap._configureSubscriptions()` deliberately returns
`NoopInstallAttributionService`. Enabling collection without the integration
would post a **per-install identifier** to a service that does nothing with it,
which is not a trade worth making — see the privacy rule in
`docs/ANALYTICS.md`.

**This costs less than it sounds.** Firebase's reporter
(`APMSearchAdReporter`) is entirely independent of RevenueCat — verified: zero
references to RevenueCat inside `GoogleAppMeasurement` — so campaign → install
→ in-app funnel reporting in GA4 works regardless. What you give up is
**revenue and LTV per campaign**, i.e. judging ads on subscriptions rather than
installs.

Practically, at $10/day, installs-per-dollar from GA4 is enough to tell whether
a keyword is worth keeping. Revisit the paid integration when spend is large
enough that the difference between a cheap install and a paying install matters
more than the subscription fee.

**To switch on:** import
`core/attribution/data/services/revenue_cat_install_attribution_service.dart`
in `app_bootstrap.dart` and return `const RevenueCatInstallAttributionService()`
instead of the no-op. The implementation and the ATT ordering are already in
place; nothing else changes.

### Why there is no `-framework AdServices` flag

Firebase's reporter is gated on AdServices being loaded in the process — it logs
*"AdServices framework is not linked. Search Ad Attribution Reporter is
disabled."* otherwise. It resolves the class at runtime rather than linking it.

**`RevenueCat.framework` already links it.** Verified on a built app:

```
$ otool -L Runner.app/Frameworks/RevenueCat.framework/RevenueCat | grep -i adservices
    /System/Library/Frameworks/AdServices.framework/AdServices
```

RevenueCat is embedded and loaded at launch, so `AAAttribution` resolves and
Firebase's reporter is enabled.

Adding `OTHER_LDFLAGS = $(inherited) -framework AdServices` to
`ios/Flutter/*.xcconfig` was tried and **removed**: the flag reaches xcodebuild
(confirmed via `xcodebuild -showBuildSettings`) but the linker dead-strips the
dylib, because `Runner` itself references no AdServices symbol. `otool -L` on
the Runner binary shows no AdServices either way — so the flag was inert
configuration that looked load-bearing. It would not help even if RevenueCat
stopped linking AdServices, for the same reason.

**The fragility to know about:** this depends on a transitive dependency of a
third-party SDK. If RevenueCat ever drops `import AdServices`, Firebase's
reporter silently switches off with no build error and no test failure. The
check is the `otool` command above — run it when upgrading `purchases_flutter`.

**The token never enters Dart.** That is deliberate: it is a per-install
identifier, and `docs/ANALYTICS.md` forbids sending identifiers. Only
campaign-level ids reach a backend, and those are shared by every install from
the same ad. Writing a Dart token fetcher would have been the one design that
put an identifier one careless `logEvent` away from the analytics port.

**Ordering with the ATT prompt.** AdServices needs no ATT consent — it is a
first-party Apple API — so collection is never gated on the user's answer.
But Apple returns richer "Detailed" data once ATT has been resolved, and
RevenueCat caches the first token it posts. So collection is enabled in
`app.dart`'s post-frame callback *after* the prompt, never in `AppBootstrap`
(which runs before the first frame). A test in
`test/app/attribution_bootstrap_order_test.dart` guards this, because the
ordering is invisible at runtime and a tidy-up refactor would silently
downgrade every install.

**You cannot test this before release.** Firebase's reporter is disabled on the
simulator by design, RevenueCat returns a canned simulator token, and
TestFlight/sandbox returns Apple's fixed test payload — Firebase even logs
*"Search Ad Reporter returned test data."* The first true validation is a real
App Store install following a real ad click. Verify the proximate signals
instead: the `otool` check above shows AdServices reaching the process, and
RevenueCat at debug log level shows the token post.

## Ad copy rules

Apple Search Ads shows your product page, so the claim audit in `docs/ASO.md`
applies to any custom product pages or ad variations too.

**Never:** diagnose, diagnosis, detect, identify, check for, screen for,
vet-approved, AI vet, veterinary advice, treatment.

**Instead:** describe, observe, record, log, compare over time, keep track.

Paw Scan may only ever be described as *describing what is visible*. See
`docs/PAW_SCAN.md` for why this is not negotiable.

## Reading the results

After roughly two weeks at this budget there should be enough to act on.

- **The search-term report is the main prize.** It shows the actual queries that
  triggered ads, which is exactly the input `docs/ASO.md` §9 wants for re-tuning
  the 100-character keyword field. The ad spend doubles as ASO research.
- Compare **cost per install** between Brand and Exact. Brand should be
  markedly cheaper; if it is not, bids are wrong somewhere.
- Judge on **subscriptions, not installs.** That needs the attribution work
  (`lib/core/attribution/`, shipping in 1.0.10) — until that is live and
  verified, Apple can tell you cost per install but nothing about whether those
  installs pay. Do not scale spend on install numbers alone.
- Move terms that do not convert to negatives rather than lowering their bids
  to nothing; it keeps the reports readable.

## Prerequisites

- [ ] Attribution shipped and verified (1.0.10) — `lib/core/attribution/`.
      **Start here**: installs that arrive before it ships are permanently
      unattributable, so every day of spend without it is wasted data.
- [ ] Listing updated to mention Paw Scan, once 1.0.9 is released.
- [ ] Rating prompt shipped, or at least a plan for getting past 8 reviews.
- [ ] Apple Search Ads account created and the payment method added.
- [ ] ~~RevenueCat → Apple Search Ads integration~~ — **deferred on purpose**
      (paid plan). Not a blocker: GA4 campaign attribution works without it.
      Revisit when judging ads on revenue rather than installs is worth the
      subscription.
- [ ] App Store Connect **App Privacy** answers re-reviewed for Advertising
      Data / Product Interaction. Note AdServices attribution is first-party
      and does not by itself constitute "tracking" under Apple's definition —
      if ASA is the only reason a "used to track you" flag is set, that flag is
      wrong and is costing ATT-prompt friction for nothing.
