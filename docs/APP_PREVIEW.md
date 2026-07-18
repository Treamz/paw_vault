# App Preview

## Marketing montage (Remotion)

A polished vertical (and square) montage video for **PawVault: Pet Health**, built
programmatically with [Remotion](https://www.remotion.dev/) (React-based video).
This montage is intended for **social media and the website** (Instagram/TikTok
Reels, X, landing-page hero, etc.).

> Note: This montage is **not** a substitute for an App Store *App Preview*. The
> App Store preview slot requires **real screen-capture footage** from a device or
> simulator. See the checklist at the bottom for producing that compliant version.

### Project location

```
marketing/app_preview/
├── public/                 # the 7 screenshots (copied from build/screenshots/iphone_6_9/)
├── src/
│   ├── index.ts            # registerRoot
│   ├── Root.tsx            # <Composition> definitions (Montage + MontageSquare)
│   └── Montage.tsx         # the video (title card, 7 segments, end card)
├── out/                    # rendered mp4s (git-ignored)
├── tsconfig.json
└── .gitignore              # ignores node_modules/, out/, .cache/
```

### Install

```bash
cd marketing/app_preview
npm install            # installs remotion, @remotion/cli, @remotion/transitions, react, react-dom
```

(First render auto-downloads a headless Chrome — let it finish.)

### Render commands

Vertical (886×1920):

```bash
cd marketing/app_preview
npx remotion render src/index.ts Montage out/pawvault_promo_886x1920.mp4 --codec=h264
```

Square (1080×1080):

```bash
cd marketing/app_preview
npx remotion render src/index.ts MontageSquare out/pawvault_promo_1080x1080.mp4 --codec=h264
```

List/inspect compositions (also handy for debugging):

```bash
npx remotion compositions src/index.ts
```

Interactive preview studio while editing:

```bash
npx remotion studio src/index.ts
```

### Composition structure

`Montage.tsx` uses `@remotion/transitions` `TransitionSeries` (fps 30):

1. **Title card** (~1.4s / 42 frames): teal gradient, animated fade + spring
   scale-in. "🐾 PawVault" + subtitle "Your pet's health, organized".
2. **7 screenshot segments** (~3.17s / 95 frames each): each screenshot sits in a
   white-bordered, rounded, shadowed "device" frame on a soft mint→teal radial
   gradient. A gentle **Ken Burns** effect (slow zoom 1.0→1.08 + a few px vertical
   drift) plays, and the matching caption animates up from the bottom in a rounded
   teal pill (spring entrance). Square variant uses a gradient bottom bar instead.
3. **End card** (~1.6s / 48 frames): teal gradient, "PawVault: Pet Health" +
   "Build your pet's health archive" + a "Download on the App Store" pill.

Transitions: ~0.53s (16-frame) crossfades — alternating `fade()` and
`slide({direction: 'from-right'})` between segments, `fade()` into the title/end.

Captions (in screenshot order), defined in the `SCREENS` array in `Montage.tsx`:

1. All your pets in one place
2. Every detail, one tidy profile
3. A full health timeline
4. Certificates & records, stored safely
5. Never miss a vaccine or dose
6. Notes into drafts you confirm
7. Share a vet summary PDF

> Medical-safety note: captions are deliberately truthful — the app **organizes**
> user-entered info (the "Notes into drafts you confirm" line reflects that AI only
> drafts content the user confirms). Do not add copy that implies diagnosis,
> treatment, or replacing a veterinarian.

### Output files + verified specs

Rendered to `marketing/app_preview/out/` and copied to `build/app_preview/`
(git-ignored):

| File | Resolution | Duration | Codec |
|------|-----------|----------|-------|
| `pawvault_promo_886x1920.mp4` | 886×1920 | 20.90 s | H.264 |
| `pawvault_promo_1080x1080.mp4` | 1080×1080 | 20.90 s | H.264 |

Verify any render:

```bash
ffprobe -v error -show_entries format=duration \
  -show_entries stream=width,height,codec_name \
  -of default=noprint_wrappers=1 build/app_preview/pawvault_promo_886x1920.mp4
```

### Tweaking captions & timing

All knobs live at the top of `marketing/app_preview/src/Montage.tsx`:

- **Captions / screenshots**: edit the `SCREENS` array.
- **Per-segment length**: `SEG_LEN` (frames @ 30fps; 95 ≈ 3.17s).
- **Title / end length**: `TITLE_LEN`, `END_LEN`.
- **Crossfade length**: `TRANS`.
- **Colors**: `TEAL`, `TEAL_DARK`, `TEAL_LIGHT`, `MINT`, `MINT_DEEP`.
- **Ken Burns intensity**: `kbScale` / `kbY` interpolations inside `Segment`.

`TOTAL_FRAMES` is computed automatically from those constants (accounting for the
overlap consumed by each `TransitionSeries.Transition`), so the composition length
stays correct when you change timings — no manual `durationInFrames` edit needed.

### Adding a licensed music track

The montage renders **silent** (no bundled/licensed audio). Two ways to add a
track once you have a properly licensed file:

**Option A — in Remotion (preferred, keeps it programmatic):**
Drop the file in `public/` and add to `Montage.tsx`:

```tsx
import {Audio, staticFile} from 'remotion';
// ...inside <AbsoluteFill> at the top level of <Montage>:
<Audio src={staticFile('music.mp3')} volume={0.6} />
```

Then re-render. You can fade the music with the `volume` callback form
(`volume={(f) => interpolate(f, [0, 15], [0, 0.6])}`).

**Option B — mux onto an existing mp4 with ffmpeg:**

```bash
ffmpeg -i build/app_preview/pawvault_promo_886x1920.mp4 -i music.mp3 \
  -map 0:v -map 1:a -c:v copy -c:a aac -shortest \
  build/app_preview/pawvault_promo_886x1920_music.mp4
```

---

## Ad creative (with audio)

A **paid-social ad** — punchier and shorter than the montage above, **with an
original music bed**. It is a separate deliverable: the montage compositions
(`Montage` / `MontageSquare`) are untouched. The ad lives in the same Remotion
project and reuses the same screenshots.

> This is a **marketing ad for paid social** (Instagram/TikTok/Reels/Meta), not
> an App Store *App Preview* (that slot still needs real screen-capture footage —
> see the checklist below).

### New compositions

Defined in `marketing/app_preview/src/Ad.tsx`, registered in `src/Root.tsx`:

| Composition | Resolution | fps | Duration |
|-------------|-----------|-----|----------|
| `Ad` | 1080×1920 (9:16, primary) | 30 | 14.70 s (441 frames) |
| `AdSquare` | 1080×1080 (1:1) | 30 | 14.70 s (441 frames) |

Both render from the same `Ad` component via a `square` prop. Structure (fast pace):

1. **Hook card** (`HOOK_LEN` 78f / ~2.6s): bold benefit statement with strong
   kinetic motion **before any screenshot** — "Your pet's whole health history —
   in one app." over a teal gradient with a rotating radial glow; lines spring up
   individually; sub-line "Stop digging through emails for vet records."
2. **6 screenshot beats** (`SHOT_LEN` 58f / ~1.93s each): screenshot in a
   rounded, shadowed device frame on a mint→teal gradient, snappy spring entrance
   (scale-in + slide from alternating sides) + quick continued zoom, with a
   pop-in teal benefit caption pill.
3. **CTA end card** (`CTA_LEN` 78f / ~2.6s): "PawVault: Pet Health" + "Build your
   pet's health archive" + a hard "Download on the App Store" pill, strong teal
   brand (`#2E7D72`).

Transitions: 9-frame (~0.3s) snappy crossfades, alternating `slide(from-right)` /
`fade()`. `AD_TOTAL_FRAMES` is computed from the timing constants (accounting for
transition overlap), so length stays correct if you retune.

**Hook copy used:**
- Headline: `Your pet's whole health history — in one app.`
- Sub-line: `Stop digging through emails for vet records.`

**Benefit captions (screenshot order):**

1. `All your pets, organized`
2. `Track every vaccine`
3. `Store every document`
4. `Never miss a dose`
5. `AI tidies your notes`
6. `Vet-ready PDF in a tap`

> Medical-safety note: every line is truthful and non-clinical. The AI caption
> ("AI tidies your notes") reflects that the assistant only **organizes**
> user-entered notes into drafts the user confirms — no diagnosis, treatment, or
> vet-replacement claims.

### Music bed (original, royalty-free)

The ad's audio is **synthesized from scratch** — no copyrighted or sampled
material — by `marketing/app_preview/scripts/make-music.mjs`. It writes raw 16-bit
PCM into a WAV: a warm C-major pad + gentle plucked arpeggio + soft kick at
~120 BPM, ~15.5s, with a 0.4s fade-in and ~1.0s fade-out. Output:
`marketing/app_preview/public/ad_music.wav` (44.1 kHz mono).

Regenerate it any time:

```bash
cd marketing/app_preview
node scripts/make-music.mjs
```

It's wired into the `Ad` component as a background bed:

```tsx
<Audio src={staticFile('ad_music.wav')} volume={0.45} />
```

**Replace with a licensed track** instead: drop your properly-licensed file in
`public/` and point the `<Audio>` `src` at it (e.g.
`staticFile('ad_track.mp3')`), then re-render. Or mux it onto a rendered mp4:

```bash
ffmpeg -i build/app_preview/pawvault_ad_1080x1920.mp4 -i your_track.mp3 \
  -map 0:v -map 1:a -c:v copy -c:a aac -shortest \
  build/app_preview/pawvault_ad_1080x1920_track.mp4
```

### Render commands

```bash
cd marketing/app_preview
npx remotion render src/index.ts Ad       out/pawvault_ad_1080x1920.mp4 --codec=h264
npx remotion render src/index.ts AdSquare out/pawvault_ad_1080x1080.mp4 --codec=h264
```

Then copy finals to the git-ignored build dir:

```bash
cp out/pawvault_ad_1080x1920.mp4 out/pawvault_ad_1080x1080.mp4 \
   ../../build/app_preview/
```

### Output files + verified specs

Rendered to `marketing/app_preview/out/` and copied to `build/app_preview/`
(git-ignored). Specs verified with `ffprobe` (incl. a real, non-silent audio
stream):

| File | Resolution | Duration | Video | Audio |
|------|-----------|----------|-------|-------|
| `pawvault_ad_1080x1920.mp4` | 1080×1920 | 14.76 s | H.264 | AAC (present, non-silent: mean −31.6 dB / max −11.3 dB) |
| `pawvault_ad_1080x1080.mp4` | 1080×1080 | 14.76 s | H.264 | AAC (present, non-silent: mean −31.6 dB / max −11.3 dB) |

Verify audio presence + level on any render:

```bash
ffprobe -v error -show_entries stream=codec_type,codec_name,width,height \
  -of default=noprint_wrappers=1 build/app_preview/pawvault_ad_1080x1920.mp4
ffmpeg -i build/app_preview/pawvault_ad_1080x1920.mp4 -af volumedetect -f null - \
  2>&1 | grep -E "mean_volume|max_volume"
```

### Tweaking the ad

Knobs at the top of `marketing/app_preview/src/Ad.tsx`:

- **Captions / screenshots**: edit the `SHOTS` array (currently 6 of 7).
- **Hook copy**: edit the strings in `HookCard`.
- **Timing**: `HOOK_LEN`, `SHOT_LEN`, `CTA_LEN`, `TRANS` (frames @ 30fps).
- **Music volume**: the `volume={0.45}` on `<Audio>` in `Ad`.
- **Colors**: `TEAL`, `TEAL_DARK`, `TEAL_LIGHT`, `MINT`, `MINT_DEEP`.

---

## App Store App Preview (compliant, full-bleed) — `AppPreview`

This is the composition to **submit to the App Store App Preview slot**. It was
created to resolve an Apple **Guideline 2.3.4** rejection: the previously
submitted `Montage` render wrapped each screenshot in a floating device card
(white border, rounded corners, drop shadow, inset on a gradient), and Apple
rejected that "framing around the video screen capture."

`AppPreview` (in `marketing/app_preview/src/AppPreview.tsx`, registered in
`src/Root.tsx`) shows every app screenshot **full-bleed, edge-to-edge** —
`objectFit: 'cover'`, **no** device frame, border, border-radius, drop shadow,
gradient background, margin, or inset. The screenshot aspect (1320/2868 =
0.4606) ≈ the frame (886/1920 = 0.4615), so `cover` crops only a negligible
sliver and the app content cleanly fills the frame. Permitted extras only:
a gentle Ken-Burns zoom (1.0→1.04), crossfade/slide transitions, and animated
lower-third **caption overlays** (overlay text is not "framing around the
capture"), plus a short (1.5s) branded end card.

> This composition is intentionally **separate** from `Montage` / `MontageSquare`
> (which keep their framed look for social/website) and from the `Ad*` paid-social
> creatives. Do not re-point the App Store slot at any of those framed renders.

### Structure (fps 30, `AppPreview` 886×1920)

`AppPreview_TOTAL_FRAMES` is computed from the timing constants (accounting for
transition overlap), so length stays valid if you retune:

1. **7 full-bleed screenshot segments** (`SEG_LEN` 90f / 3.0s each): screenshot
   fills the whole frame via `objectFit: 'cover'` with a subtle Ken-Burns zoom;
   a teal caption pill springs up in the lower third.
2. **Branded end card** (`END_LEN` 45f / 1.5s): "🐾 PawVault: Pet Health" +
   "Build your pet's health archive" on a teal gradient.

Transitions: 15f (0.5s) crossfades, alternating `slide(from-right)` / `fade()`.

Captions are the same truthful, non-clinical lines as the montage `SCREENS`
array (see medical-safety note above).

### Render + verify

```bash
cd marketing/app_preview
npx remotion render src/index.ts AppPreview out/pawvault_apppreview_886x1920.mp4 --codec=h264
cp out/pawvault_apppreview_886x1920.mp4 ../../build/app_preview/

ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,codec_name -show_entries format=duration \
  -of default=noprint_wrappers=1 out/pawvault_apppreview_886x1920.mp4
```

### Output + verified specs

| File | Resolution | Duration | Codec |
|------|-----------|----------|-------|
| `pawvault_apppreview_886x1920.mp4` | 886×1920 | 19.00 s | H.264 |

Within the App Preview limits (15–30 s) and exactly 886×1920 portrait.

### Tweaking

Knobs at the top of `marketing/app_preview/src/AppPreview.tsx`: `SCREENS`
(screenshots + captions), `SEG_LEN` / `END_LEN` / `TRANS` (frames @ 30fps),
`kbScale` Ken-Burns range, brand colors. Keep the screenshot full-bleed — do
**not** re-introduce any border/radius/shadow/background inset or Apple will
reject again under 2.3.4.

To add a poster frame / music, see the montage's audio section above (silent by
default — App Previews don't require audio).

---

## (Historical) App Store App Preview — manual screen-capture route

> Superseded by the programmatic `AppPreview` composition above, which is the
> current compliant deliverable. Kept for reference if a real screen-capture
> pass is ever preferred.

The montage above is for social/website. A screen-capture App Preview uses
real device footage instead of composited screenshots. To produce it that way:

- **Length**: 15–30 seconds.
- **Capture real footage** from a simulator (or device) — actual app navigation:

  ```bash
  xcrun simctl list devices           # find the booted device UDID
  xcrun simctl io <udid> recordVideo --codec=h264 preview.mov
  # ...interact with the app...  Ctrl-C to stop recording
  ```

  (For a physical device, capture via QuickTime "New Movie Recording".)
- **Per-device resolutions** (portrait):
  - iPhone 6.9″ — **1290×2796**
  - iPad 13″ — **2064×2752**
- Trim/assemble in iMovie, Final Cut, or ffmpeg; keep it to real UI motion (App
  Store rejects previews that are just static marketing graphics).
- Upload one App Preview per required device size in App Store Connect.
