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
// Brand constants
// ---------------------------------------------------------------------------
const TEAL = '#2E7D72';
const TEAL_DARK = '#205A52';
const TEAL_LIGHT = '#3E9D90';
const MINT = '#F1F7F4';
const MINT_DEEP = '#DCEBE6';

const FONT =
  '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif';

// ---------------------------------------------------------------------------
// Timing (frames @ 30fps)
// ---------------------------------------------------------------------------
const TITLE_LEN = 42; // ~1.4s
const SEG_LEN = 95; // ~3.17s per screenshot
const END_LEN = 48; // ~1.6s
const TRANS = 16; // crossfade length

const SCREENS = [
  {src: '01_pets.png', caption: 'All your pets in one place'},
  {src: '02_profile.png', caption: 'Every detail, one tidy profile'},
  {src: '03_timeline.png', caption: 'A full health timeline'},
  {src: '04_documents.png', caption: 'Certificates & records, stored safely'},
  {src: '05_reminders.png', caption: 'Never miss a vaccine or dose'},
  {src: '06_smart_input.png', caption: 'Notes into drafts you confirm'},
  {src: '07_vet_summary.png', caption: 'Share a vet summary PDF'},
];

// TransitionSeries total = sum(sequence durations) - sum(transition durations)
const SEQ_COUNT = 1 /*title*/ + SCREENS.length + 1 /*end*/;
const TRANS_COUNT = SEQ_COUNT - 1;
export const TOTAL_FRAMES =
  TITLE_LEN + SCREENS.length * SEG_LEN + END_LEN - TRANS_COUNT * TRANS;

// ---------------------------------------------------------------------------
// Shared gradient background
// ---------------------------------------------------------------------------
const GradientBg: React.FC = () => {
  const frame = useCurrentFrame();
  const drift = interpolate(frame % 300, [0, 300], [0, 30]);
  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(120% 100% at ${50 + drift / 6}% 0%, ${MINT} 0%, ${MINT_DEEP} 60%, #CFE3DD 100%)`,
      }}
    />
  );
};

// ---------------------------------------------------------------------------
// Title card
// ---------------------------------------------------------------------------
const TitleCard: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  const enter = spring({frame, fps, config: {damping: 14, mass: 0.8}});
  const scale = interpolate(enter, [0, 1], [0.82, 1]);
  const opacity = interpolate(frame, [0, 12], [0, 1], {
    extrapolateRight: 'clamp',
  });
  const subOpacity = interpolate(frame, [10, 24], [0, 1], {
    extrapolateRight: 'clamp',
    extrapolateLeft: 'clamp',
  });

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(160deg, ${TEAL_LIGHT} 0%, ${TEAL} 45%, ${TEAL_DARK} 100%)`,
        justifyContent: 'center',
        alignItems: 'center',
      }}
    >
      <div
        style={{
          transform: `scale(${scale})`,
          opacity,
          textAlign: 'center',
        }}
      >
        <div
          style={{
            fontSize: 92,
            lineHeight: 1.5,
          }}
        >
          🐾
        </div>
        <div
          style={{
            fontFamily: FONT,
            fontWeight: 800,
            fontSize: 120,
            color: '#FFFFFF',
            letterSpacing: -2,
          }}
        >
          PawVault
        </div>
        <div
          style={{
            fontFamily: FONT,
            fontWeight: 500,
            fontSize: 46,
            color: 'rgba(255,255,255,0.92)',
            marginTop: 14,
            opacity: subOpacity,
          }}
        >
          Your pet's health, organized
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ---------------------------------------------------------------------------
// Screenshot segment with Ken Burns + caption pill
// ---------------------------------------------------------------------------
const Segment: React.FC<{
  src: string;
  caption: string;
  square: boolean;
}> = ({src, caption, square}) => {
  const frame = useCurrentFrame();
  const {fps, height} = useVideoConfig();

  // Ken Burns: slow zoom + drift
  const kbScale = interpolate(frame, [0, SEG_LEN], [1.0, 1.08]);
  const kbY = interpolate(frame, [0, SEG_LEN], [10, -18]);

  // Device frame fitted by height with margins.
  const deviceHeight = square ? height * 1.05 : height * 0.82;

  // Caption entrance
  const capSpring = spring({
    frame: frame - 8,
    fps,
    config: {damping: 16, mass: 0.7},
  });
  const capY = interpolate(capSpring, [0, 1], [80, 0]);
  const capOpacity = interpolate(frame, [8, 20], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill>
      <GradientBg />
      {/* Device */}
      <AbsoluteFill
        style={{
          justifyContent: 'center',
          alignItems: 'center',
          paddingBottom: square ? 0 : 120,
        }}
      >
        <div
          style={{
            transform: `translateY(${kbY}px) scale(${kbScale})`,
            borderRadius: 56,
            overflow: 'hidden',
            boxShadow:
              '0 40px 90px rgba(32,90,82,0.32), 0 8px 24px rgba(32,90,82,0.18)',
            border: '8px solid rgba(255,255,255,0.85)',
            height: deviceHeight,
            aspectRatio: '1320 / 2868',
          }}
        >
          <Img
            src={staticFile(src)}
            style={{
              height: '100%',
              width: '100%',
              objectFit: 'cover',
              display: 'block',
            }}
          />
        </div>
      </AbsoluteFill>

      {/* Caption lower-third pill */}
      {!square && (
        <AbsoluteFill
          style={{
            justifyContent: 'flex-end',
            alignItems: 'center',
            paddingBottom: 90,
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
              fontSize: 50,
              lineHeight: 1.25,
              textAlign: 'center',
              padding: '30px 54px',
              borderRadius: 80,
              maxWidth: 900,
              boxShadow: '0 18px 40px rgba(32,90,82,0.35)',
            }}
          >
            {caption}
          </div>
        </AbsoluteFill>
      )}

      {/* Square variant caption: bottom bar */}
      {square && (
        <AbsoluteFill
          style={{justifyContent: 'flex-end', alignItems: 'center'}}
        >
          <div
            style={{
              transform: `translateY(${capY}px)`,
              opacity: capOpacity,
              width: '100%',
              background: `linear-gradient(0deg, rgba(32,90,82,0.92) 0%, rgba(32,90,82,0.0) 100%)`,
              color: '#FFFFFF',
              fontFamily: FONT,
              fontWeight: 700,
              fontSize: 44,
              textAlign: 'center',
              padding: '120px 40px 44px',
            }}
          >
            {caption}
          </div>
        </AbsoluteFill>
      )}
    </AbsoluteFill>
  );
};

// ---------------------------------------------------------------------------
// End card
// ---------------------------------------------------------------------------
const EndCard: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const enter = spring({frame, fps, config: {damping: 16}});
  const scale = interpolate(enter, [0, 1], [0.9, 1]);
  const opacity = interpolate(frame, [0, 12], [0, 1], {
    extrapolateRight: 'clamp',
  });
  const storeOpacity = interpolate(frame, [14, 28], [0, 1], {
    extrapolateLeft: 'clamp',
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
            fontSize: 78,
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
            fontSize: 44,
            color: 'rgba(255,255,255,0.92)',
            marginTop: 14,
          }}
        >
          Build your pet's health archive
        </div>
        <div
          style={{
            opacity: storeOpacity,
            marginTop: 56,
            display: 'inline-block',
            fontFamily: FONT,
            fontWeight: 600,
            fontSize: 36,
            color: TEAL_DARK,
            background: '#FFFFFF',
            padding: '20px 40px',
            borderRadius: 60,
            boxShadow: '0 14px 34px rgba(0,0,0,0.22)',
          }}
        >
          Download on the App Store
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ---------------------------------------------------------------------------
// Main montage
// ---------------------------------------------------------------------------
export const Montage: React.FC<{square: boolean}> = ({square}) => {
  return (
    <AbsoluteFill style={{backgroundColor: MINT}}>
      <TransitionSeries>
        <TransitionSeries.Sequence durationInFrames={TITLE_LEN}>
          <TitleCard />
        </TransitionSeries.Sequence>

        <TransitionSeries.Transition
          presentation={fade()}
          timing={linearTiming({durationInFrames: TRANS})}
        />

        {SCREENS.map((s, i) => (
          <React.Fragment key={s.src}>
            <TransitionSeries.Sequence durationInFrames={SEG_LEN}>
              <Segment src={s.src} caption={s.caption} square={square} />
            </TransitionSeries.Sequence>
            <TransitionSeries.Transition
              presentation={
                i % 2 === 0
                  ? slide({direction: 'from-right'})
                  : fade()
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
