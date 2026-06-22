import React from 'react';
import {
  AbsoluteFill,
  Img,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {TransitionSeries, linearTiming} from '@remotion/transitions';
import {fade} from '@remotion/transitions/fade';
import {slide} from '@remotion/transitions/slide';

// ---------------------------------------------------------------------------
// App Store APP PREVIEW — full-bleed, compliant version.
//
// Apple Guideline 2.3.4 rejects any framing around the screen capture (device
// bezel, border, rounded corners, drop shadow, inset on a background). So every
// screenshot here fills the ENTIRE 886x1920 frame edge-to-edge via
// `objectFit: 'cover'` — no frame, no border, no radius, no shadow, no gradient
// background. The screenshot aspect (1320/2868 = 0.4606) ~ target
// (886/1920 = 0.4615), so `cover` crops a negligible sliver.
//
// Only a subtle Ken-Burns move + crossfades + lower-third caption overlays are
// applied (overlays are not "framing around the screen capture"). A short
// branded end card closes it out. This composition is intentionally SEPARATE
// from `Montage`/`Segment` so the social creatives keep their device framing.
// ---------------------------------------------------------------------------

const TEAL = '#2E7D72';
const TEAL_DARK = '#205A52';
const TEAL_LIGHT = '#3E9D90';
const MINT = '#F1F7F4';

const FONT =
  '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif';

// ---------------------------------------------------------------------------
// Timing (frames @ 30fps)
// ---------------------------------------------------------------------------
const SEG_LEN = 90; // 3.0s per screenshot
const END_LEN = 45; // 1.5s branded end card
const TRANS = 15; // 0.5s crossfade

const SCREENS = [
  {src: '01_pets.png', caption: 'All your pets in one place'},
  {src: '02_profile.png', caption: 'Every detail, one tidy profile'},
  {src: '03_timeline.png', caption: 'A full health timeline'},
  {src: '04_documents.png', caption: 'Certificates & records, stored safely'},
  {src: '05_reminders.png', caption: 'Never miss a vaccine or dose'},
  {src: '06_smart_input.png', caption: 'Notes into drafts you confirm'},
  {src: '07_vet_summary.png', caption: 'Share a vet summary PDF'},
];

// TransitionSeries total = sum(sequence durations) - sum(transition durations).
const SEQ_COUNT = SCREENS.length + 1 /*end card*/;
const TRANS_COUNT = SEQ_COUNT - 1;
export const APP_PREVIEW_TOTAL_FRAMES =
  SCREENS.length * SEG_LEN + END_LEN - TRANS_COUNT * TRANS;

// ---------------------------------------------------------------------------
// Full-bleed screenshot segment: app fills the entire frame, edge-to-edge.
// ---------------------------------------------------------------------------
const FullBleedSegment: React.FC<{
  src: string;
  caption: string;
}> = ({src, caption}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  // Subtle Ken Burns: slow zoom only (kept gentle so the app content always
  // covers the frame edge-to-edge — no transparent gutters can appear).
  const kbScale = interpolate(frame, [0, SEG_LEN], [1.0, 1.04]);

  // Caption entrance (lower-third overlay, not framing around the capture).
  const capSpring = spring({
    frame: frame - 6,
    fps,
    config: {damping: 16, mass: 0.7},
  });
  const capY = interpolate(capSpring, [0, 1], [70, 0]);
  const capOpacity = interpolate(frame, [6, 18], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill style={{backgroundColor: MINT}}>
      {/* App screenshot fills the WHOLE frame, edge-to-edge. */}
      <AbsoluteFill style={{transform: `scale(${kbScale})`}}>
        <Img
          src={staticFile(src)}
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'cover',
            display: 'block',
          }}
        />
      </AbsoluteFill>

      {/* Lower-third caption (overlay text — permitted). */}
      <AbsoluteFill
        style={{
          justifyContent: 'flex-end',
          alignItems: 'center',
          paddingBottom: 96,
        }}
      >
        <div
          style={{
            transform: `translateY(${capY}px)`,
            opacity: capOpacity,
            background: `linear-gradient(135deg, ${TEAL} 0%, ${TEAL_DARK} 100%)`,
            color: '#FFFFFF',
            fontFamily: FONT,
            fontWeight: 700,
            fontSize: 44,
            lineHeight: 1.25,
            textAlign: 'center',
            padding: '26px 46px',
            borderRadius: 70,
            maxWidth: 780,
            boxShadow: '0 18px 40px rgba(32,90,82,0.35)',
          }}
        >
          {caption}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// ---------------------------------------------------------------------------
// Short branded end card.
// ---------------------------------------------------------------------------
const EndCard: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const enter = spring({frame, fps, config: {damping: 16}});
  const scale = interpolate(enter, [0, 1], [0.9, 1]);
  const opacity = interpolate(frame, [0, 12], [0, 1], {
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(160deg, ${TEAL_LIGHT} 0%, ${TEAL} 45%, ${TEAL_DARK} 100%)`,
        justifyContent: 'center',
        alignItems: 'center',
      }}
    >
      <div style={{transform: `scale(${scale})`, opacity, textAlign: 'center'}}>
        <div style={{fontSize: 76}}>🐾</div>
        <div
          style={{
            fontFamily: FONT,
            fontWeight: 800,
            fontSize: 72,
            color: '#FFFFFF',
            letterSpacing: -1,
            marginTop: 8,
          }}
        >
          PawVault: Pet Health
        </div>
        <div
          style={{
            fontFamily: FONT,
            fontWeight: 500,
            fontSize: 42,
            color: 'rgba(255,255,255,0.92)',
            marginTop: 14,
          }}
        >
          Build your pet's health archive
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ---------------------------------------------------------------------------
// App Preview composition.
// ---------------------------------------------------------------------------
export const AppPreview: React.FC = () => {
  return (
    <AbsoluteFill style={{backgroundColor: MINT}}>
      <TransitionSeries>
        {SCREENS.map((s, i) => (
          <React.Fragment key={s.src}>
            <TransitionSeries.Sequence durationInFrames={SEG_LEN}>
              <FullBleedSegment src={s.src} caption={s.caption} />
            </TransitionSeries.Sequence>
            <TransitionSeries.Transition
              presentation={
                i % 2 === 0 ? slide({direction: 'from-right'}) : fade()
              }
              timing={linearTiming({durationInFrames: TRANS})}
            />
          </React.Fragment>
        ))}

        <TransitionSeries.Sequence durationInFrames={END_LEN}>
          <EndCard />
        </TransitionSeries.Sequence>
      </TransitionSeries>
    </AbsoluteFill>
  );
};
