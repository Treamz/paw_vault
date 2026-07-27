---
description: Fix a QA issue end-to-end (plan → fix → tests → integration test with screenshots → verify/repeat)
---

Fix this QA issue: $ARGUMENTS

Follow this workflow strictly, in order:

## 1. Plan
- Locate the affected code (screens, cubits, repositories) by reading it — do not guess.
- Write a short plan first: root cause, files to change, test strategy. Present it before coding.

## 2. Fix
- Create (or stay on) a `fix/<slug>` branch per the git workflow rules.
- Implement the minimal change following the architecture rules in CLAUDE.md:
  UI → Cubit → Repository interface → Data source; no Firebase SDK access in UI or cubits.

## 3. Tests
- Add or update unit/widget tests for the changed logic.
- Run the required checks; all must pass:
  `dart format .` && `flutter analyze` && `flutter test`

## 4. Integration test with screenshots
- Add or extend a test in `integration_test/` that drives the real app (`PawVaultApp` with
  `AppDependencies` where only platform/Firebase boundaries are faked) through the fixed flow.
- Call `binding.convertFlutterSurfaceToImage()` once, then `binding.takeScreenshot('NN_name')`
  at each key step.
- Run on a booted iOS simulator so screenshots are written to disk:
  `SCREENSHOT_DIR=build/verify_screenshots flutter drive --driver=test_driver/screenshots.dart --target=integration_test/<test>.dart -d <simulator-udid>`
- Open and visually inspect the saved PNGs — the assertions passing is not enough; the screen
  must look right.

## 5. Verify / repeat
- If the test fails or a screenshot looks wrong: fix and repeat from step 2.
- When green and visually correct: commit with a short imperative message.
- Never push `v*` tags as part of an issue fix — tags trigger the TestFlight CI build.
