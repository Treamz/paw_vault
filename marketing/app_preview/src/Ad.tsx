import React from 'react';
import {
  AbsoluteFill,
  Audio,
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
// Paid-social AD creative for "PawVault: Pet Health" — ~15s, fast pace, audio.
// Separate from the store Montage. Compositions: Ad (1080x1920), AdSquare
// (1080x1080), both 30fps. Hook -> 5 snappy screenshot beats -> CTA end card.
// ---------------------------------------------------------------------------

// Brand
const TEAL = '#2E7D72';
const TEAL_DARK = '#205A52';
const TEAL_LIGHT = '#3E9D90';
const MINT = '#F1F7F4';
const MINT_DEEP = '#DCEBE6';

const FONT =
  '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif';

// ---------------------------------------------------------------------------
// Timing (frames @ 30fps). Tuned for ~15s.
// ---------------------------------------------------------------------------
const HOOK_LEN = 78; // ~2.6s hook before any screenshot
const SHOT_LEN = 58; // ~1.93s per screenshot
const CTA_LEN = 78; // ~2.6s CTA end card
const TRANS = 9; // ~0.3s snappy crossfade

// 6 of the 7 screenshots — the most ad-compelling, each with a short benefit.
const SHOTS = [
  {src: '01_pets.png', caption: 'All your pets, organized'},
  {src: '03_timeline.png', caption: 'Track every vaccine'},
  {src: '04_documents.png', caption: 'Store every document'},
  {src: '05_reminders.png', caption: 'Never miss a dose'},
  {src: '06_smart_input.png', caption: 'AI tidies your notes'},
  {src: '07_vet_summary.png', caption: 'Vet-ready PDF in a tap'},
];

// TransitionSeries total = sum(seq) - sum(transitions)
const SEQ_COUNT = 1 /*hook*/ + SHOTS.length + 1 /*cta*/;
const TRANS_COUNT = SEQ_COUNT - 1;
export const AD_TOTAL_FRAMES =
  HOOK_LEN + SHOTS.length * SHOT_LEN + CTA_LEN - TRANS_COUNT * TRANS;

// ---------------------------------------------------------------------------
// Hook card — bold, truthful benefit statement with strong motion.
// ---------------------------------------------------------------------------
const HookCard: React.FC<{square: boolean}> = ({square}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  const enter = spring({frame, fps, config: {damping: 12, mass: 0.7}});
  const opacity = interpolate(frame, [0, 8], [0, 1], {extrapolateRight: 'clamp'});

  // Animated drifting glow for energy.
  const glow = interpolate(frame % 80, [0, 80], [0, 360]);

  // Each line slides up on its own spring for kinetic feel.
  const line2 = spring({frame: frame - 7, fps, config: {damping: 13}});
  const line3 = spring({frame: frame - 14, fps, config: {damping: 13}});

  const big = square ? 96 : 110;
  const sub = square ? 40 : 46;

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(155deg, ${TEAL_LIGHT} 0%, ${TEAL} 48%, ${TEAL_DARK} 100%)`,
        justifyContent: 'center',
        alignItems: 'center',
        overflow: 'hidden',
      }}
    >
      {/* rotating radial glow */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(60% 40% at ${50 + 18 * Math.cos((glow * Math.PI) / 180)}% ${
            40 + 14 * Math.sin((glow * Math.PI) / 180)
          }%, rgba(255,255,255,0.22) 0%, rgba(255,255,255,0) 60%)`,
        }}
      />
      <div
        style={{
          transform: `scale(${interpolate(enter, [0, 1], [0.86, 1])})`,
          opacity,
          textAlign: 'center',
          padding: '0 70px',
        }}
      >
        <div
          style={{
            fontFamily: FONT,
            fontWeight: 800,
            fontSize: big,
            lineHeight: 1.06,
            color: '#FFFFFF',
            letterSpacing: -2,
          }}
        >
          <div>Your pet's whole</div>
          <div
            style={{
              transform: `translateY(${interpolate(line2, [0, 1], [60, 0])}px)`,
              opacity: line2,
            }}
          >
            health history
          </div>
          <div
            style={{
              transform: `translateY(${interpolate(line3, [0, 1], [60, 0])}px)`,
              opacity: line3,
              color: '#EAF6F2',
            }}
          >
            — in one app.
          </div>
        </div>
        <div
          style={{
            fontFamily: FONT,
            fontWeight: 500,
            fontSize: sub,
            color: 'rgba(255,255,255,0.92)',
            marginTop: 34,
            opacity: interpolate(frame, [20, 34], [0, 1], {
              extrapolateLeft: 'clamp',
              extrapolateRight: 'clamp',
            }),
          }}
        >
          Stop digging through emails for vet records.
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ---------------------------------------------------------------------------
// Screenshot beat — energetic spring scale/slide + snappy benefit caption.
// ---------------------------------------------------------------------------
const GradientBg: React.FC = () => {
  const frame = useCurrentFrame();
  const drift = interpolate(frame % 120, [0, 120], [0, 24]);
  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(120% 100% at ${50 + drift / 6}% 0%, ${MINT} 0%, ${MINT_DEEP} 58%, #CFE3DD 100%)`,
      }}
    />
  );
};

const Shot: React.FC<{
  src: string;
  caption: string;
  square: boolean;
  index: number;
}> = ({src, caption, square, index}) => {
  const frame = useCurrentFrame();
  const {fps, height} = useVideoConfig();

  // Snappy spring entrance: scale-in + slide from alternating sides.
  const enter = spring({frame, fps, config: {damping: 13, mass: 0.6}});
  const dir = index % 2 === 0 ? 1 : -1;
  const slideX = interpolate(enter, [0, 1], [120 * dir, 0]);
  const scaleIn = interpolate(enter, [0, 1], [0.84, 1]);

  // Quick continued zoom for energy.
  const kbScale = interpolate(frame, [0, SHOT_LEN], [1.0, 1.05]);

  const deviceHeight = square ? height * 1.0 : height * 0.78;

  // Caption pops in fast.
  const capSpring = spring({
    frame: frame - 4,
    fps,
    config: {damping: 12, mass: 0.5},
  });
  const capScale = interpolate(capSpring, [0, 1], [0.6, 1]);
  const capOpacity = interpolate(frame, [4, 12], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill>
      <GradientBg />
      <AbsoluteFill
        style={{
          justifyContent: 'center',
          alignItems: 'center',
          paddingBottom: square ? 0 : 150,
        }}
      >
        <div
          style={{
            transform: `translateX(${slideX}px) scale(${scaleIn * kbScale})`,
            borderRadius: 52,
            overflow: 'hidden',
            boxShadow:
              '0 40px 90px rgba(32,90,82,0.32), 0 8px 24px rgba(32,90,82,0.18)',
            border: '8px solid rgba(255,255,255,0.9)',
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

      {/* Snappy benefit caption */}
      <AbsoluteFill
        style={{
          justifyContent: 'flex-end',
          alignItems: 'center',
          paddingBottom: square ? 56 : 110,
        }}
      >
        <div
          style={{
            transform: `scale(${capScale})`,
            opacity: capOpacity,
            background: `linear-gradient(135deg, ${TEAL} 0%, ${TEAL_DARK} 100%)`,
            color: '#FFFFFF',
            fontFamily: FONT,
            fontWeight: 800,
            fontSize: square ? 52 : 58,
            textAlign: 'center',
            padding: square ? '24px 46px' : '28px 56px',
            borderRadius: 80,
            maxWidth: '90%',
            letterSpacing: -0.5,
            boxShadow: '0 18px 40px rgba(32,90,82,0.4)',
          }}
        >
          {caption}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// ---------------------------------------------------------------------------
// CTA end card — hard CTA, strong teal brand.
// ---------------------------------------------------------------------------
const CtaCard: React.FC<{square: boolean}> = ({square}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const enter = spring({frame, fps, config: {damping: 14, mass: 0.7}});
  const scale = interpolate(enter, [0, 1], [0.88, 1]);
  const opacity = interpolate(frame, [0, 10], [0, 1], {extrapolateRight: 'clamp'});

  const pill = spring({frame: frame - 12, fps, config: {damping: 11, mass: 0.5}});
  const pillScale = interpolate(pill, [0, 1], [0.6, 1]);
  const pillOpacity = interpolate(frame, [12, 22], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(155deg, ${TEAL_LIGHT} 0%, ${TEAL} 48%, ${TEAL_DARK} 100%)`,
        justifyContent: 'center',
        alignItems: 'center',
      }}
    >
      <div style={{transform: `scale(${scale})`, opacity, textAlign: 'center'}}>
        <div style={{fontSize: square ? 80 : 92}}>🐾</div>
        <div
          style={{
            fontFamily: FONT,
            fontWeight: 800,
            fontSize: square ? 80 : 92,
            color: '#FFFFFF',
            letterSpacing: -1.5,
            marginTop: 10,
          }}
        >
          PawVault: Pet Health
        </div>
        <div
          style={{
            fontFamily: FONT,
            fontWeight: 500,
            fontSize: square ? 40 : 46,
            color: 'rgba(255,255,255,0.92)',
            marginTop: 16,
          }}
        >
          Build your pet's health archive
        </div>
        <div
          style={{
            transform: `scale(${pillScale})`,
            opacity: pillOpacity,
            marginTop: 56,
            display: 'inline-block',
            fontFamily: FONT,
            fontWeight: 700,
            fontSize: square ? 40 : 44,
            color: TEAL_DARK,
            background: '#FFFFFF',
            padding: '24px 52px',
            borderRadius: 70,
            boxShadow: '0 16px 40px rgba(0,0,0,0.28)',
          }}
        >
           Download on the App Store
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ---------------------------------------------------------------------------
// Main Ad — background music bed + fast sequence.
// ---------------------------------------------------------------------------
export const Ad: React.FC<{square: boolean}> = ({square}) => {
  return (
    <AbsoluteFill style={{backgroundColor: MINT}}>
      {/* Original royalty-free music bed (see scripts/make-music.mjs). */}
      <Audio src={staticFile('ad_music.wav')} volume={0.45} />

      <TransitionSeries>
        <TransitionSeries.Sequence durationInFrames={HOOK_LEN}>
          <HookCard square={square} />
        </TransitionSeries.Sequence>

        <TransitionSeries.Transition
          presentation={fade()}
          timing={linearTiming({durationInFrames: TRANS})}
        />

        {SHOTS.map((s, i) => (
          <React.Fragment key={s.src}>
            <TransitionSeries.Sequence durationInFrames={SHOT_LEN}>
              <Shot src={s.src} caption={s.caption} square={square} index={i} />
            </TransitionSeries.Sequence>
            <TransitionSeries.Transition
              presentation={
                i % 2 === 0 ? slide({direction: 'from-right'}) : fade()
              }
              timing={linearTiming({durationInFrames: TRANS})}
            />
          </React.Fragment>
        ))}

        <TransitionSeries.Sequence durationInFrames={CTA_LEN}>
          <CtaCard square={square} />
        </TransitionSeries.Sequence>
      </TransitionSeries>
    </AbsoluteFill>
  );
};
