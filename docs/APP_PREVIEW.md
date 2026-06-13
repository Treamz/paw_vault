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

## App Store App Preview (compliant version — checklist)

The montage above is for social/website. The App Store **App Preview** slot needs
real screen-capture footage, not composited screenshots. To produce it later:

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
