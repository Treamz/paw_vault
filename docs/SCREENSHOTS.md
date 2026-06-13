# App Store screenshots

Screenshots are generated automatically by rendering each screen with seeded
sample data — no manual tapping, no Firebase, no network. This keeps them
consistent and reproducible at the exact pixel sizes Apple requires.

## How it works

- `integration_test/screenshots_test.dart` — pumps each primary screen wrapped
  in the app theme with in-memory fakes, and calls `takeScreenshot` for each.
- `integration_test/support/fakes.dart` — in-memory repositories that return
  seeded data from their streams.
- `integration_test/support/sample_data.dart` — the showcase content (pets,
  timeline events, documents, reminders, smart-input entries, exports). Edit
  this to change what appears in the screenshots.
- `test_driver/screenshots.dart` — writes each screenshot's PNG bytes to disk.
- `tool/screenshots.sh` — boots each required simulator and runs the suite.

Captured screens: pet list, pet profile, health timeline, documents, reminders,
smart input, and vet summary export.

## Generate

```bash
tool/screenshots.sh            # all required sizes (iPhone 6.9" + iPad 13")
tool/screenshots.sh iphone     # iPhone 6.9" only  (iPhone 16 Pro Max)
tool/screenshots.sh ipad       # iPad 13" only     (iPad Pro 13-inch M4)
```

Output:

```
build/screenshots/iphone_6_9/01_pets.png … 07_vet_summary.png   (1320 x 2868)
build/screenshots/ipad_13/01_pets.png    … 07_vet_summary.png   (2064 x 2752)
```

`build/` is git-ignored, so the PNGs stay local — regenerate any time.

## Required sizes (App Store Connect, 2024+)

| Display | Simulator | Pixels |
| --- | --- | --- |
| iPhone 6.9" | iPhone 16 Pro Max | 1320 × 2868 |
| iPad 13" | iPad Pro 13-inch (M4) | 2064 × 2752 |

The iPad set is required **while the app targets iPad**
(`TARGETED_DEVICE_FAMILY = 1,2`). If iPad support is dropped (set it to `1`),
App Store Connect no longer asks for iPad screenshots and `tool/screenshots.sh
iphone` is enough.

## Uploading

In App Store Connect → your app → the version → **Previews and Screenshots**,
drag the PNGs into the matching device size. The same 6.9" set also covers the
6.5"/6.7" slots if you choose to fill them.

## Notes

- To add or reorder screens, edit `screenshots_test.dart`; the numeric filename
  prefixes (`01_`, `02_`, …) control upload ordering.
- These files live under `integration_test/` and dev-only dependencies; they are
  not part of the shipping app.
