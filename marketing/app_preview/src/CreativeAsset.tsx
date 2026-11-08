import React from 'react';
import {AbsoluteFill, Img, staticFile} from 'remotion';

// ---------------------------------------------------------------------------
// App Store CREATIVE ASSET — the product page header and the search result.
//
// Apple takes one "universal" asset for both slots, which is why 5244x2950
// appears under each of them in the asset library catalogue:
//
//   PRODUCT_PAGE_HEADER_ASSET       i5244x2950a0, i3840x1646a0, video
//   APP_STORE_SEARCH_RESULTS_ASSET  i5244x2950a0, 3:2 w1920~3840, video
//
// So this renders at 5244x2950 and serves both.
//
// SAFE AREA. The same file is cropped to each slot's own ratio, and Apple asks
// for the focal point to survive that. Both crops are centred, so:
//
//   to 3:2      -> 4425x2950, losing 410px off each side
//   to 2.33:1   -> 5244x2250, losing 350px off the top and bottom
//
// The intersection is the middle 4425x2250, and nothing that matters may sit
// outside it. SAFE below is that rectangle; the background bleeds past it on
// purpose, because a background has nothing to lose to a crop.
//
// What the asset may not contain, from Apple's asset best practices: prices or
// discounts, website URLs, copyright symbols, awards the app has not received,
// other platforms' logos, or any Apple recognition such as Editor's Choice. It
// also has to read as 4+. The headline is deliberately a short phrase rather
// than a description of the picture.
// ---------------------------------------------------------------------------

export const CREATIVE_WIDTH = 5244;
export const CREATIVE_HEIGHT = 2950;

const SAFE = {
  width: 4425,
  height: 2250,
  left: (CREATIVE_WIDTH - 4425) / 2,
  top: (CREATIVE_HEIGHT - 2250) / 2,
};

/// Margin kept inside the safe rect on both sides.
const INSET = 130;

const TEAL = '#2E7D72';
const TEAL_DARK = '#1C4F48';
const MINT = '#F1F7F4';
const MINT_DEEP = '#D7EAE3';

const FONT =
  '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", Roboto, Helvetica, Arial, sans-serif';

/// The three screens that say most about the app at a glance: the pets you
/// keep, one pet's record, and the documents behind it.
const SHOTS = ['01_pets.png', '02_profile.png', '04_documents.png'];

const PHONE_WIDTH = 660;
// The captures are 1320x2868, so the height follows from the width rather
// than being eyeballed; getting it wrong squashes the UI inside.
const PHONE_HEIGHT = Math.round((PHONE_WIDTH * 2868) / 1320);

const Phone: React.FC<{src: string; index: number}> = ({src, index}) => {
  // A shallow fan with the middle phone forward. The first attempt overlapped
  // them by 96px and tilted 4 degrees, which cut the right phone's title to
  // "...cuments" and hid half the list on the left one, so they sit apart now
  // and lean barely enough to read as a set.
  const rotate = (index - 1) * 2.5;
  const lift = index === 1 ? 0 : 70;

  return (
    <div
      style={{
        width: PHONE_WIDTH,
        height: PHONE_HEIGHT,
        marginLeft: index === 0 ? 0 : 34,
        marginTop: lift,
        transform: `rotate(${rotate}deg)`,
        borderRadius: 62,
        overflow: 'hidden',
        backgroundColor: '#FFFFFF',
        boxShadow: '0 44px 100px rgba(28, 79, 72, 0.26)',
        zIndex: index === 1 ? 2 : 1,
        flexShrink: 0,
      }}
    >
      <Img
        src={staticFile(src)}
        style={{width: '100%', height: '100%', objectFit: 'cover'}}
      />
    </div>
  );
};

export const CreativeAsset: React.FC = () => {
  return (
    <AbsoluteFill style={{backgroundColor: MINT, fontFamily: FONT}}>
      {/* Background only — it may be cropped away without costing anything. */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(120% 90% at 78% 50%, ${MINT_DEEP} 0%, ${MINT} 62%)`,
        }}
      />

      <AbsoluteFill
        style={{
          left: SAFE.left,
          top: SAFE.top,
          width: SAFE.width,
          height: SAFE.height,
          display: 'flex',
          flexDirection: 'row',
          alignItems: 'center',
          justifyContent: 'space-between',
          // The safe rect is a limit, not a content box. Sitting flush against
          // it let a crop shave the icon on one side and the leaning phone's
          // shadow on the other, so keep everything a margin inside it.
          paddingLeft: INSET,
          paddingRight: INSET,
        }}
      >
        <div style={{width: 1760, paddingRight: 80}}>
          <div style={{display: 'flex', alignItems: 'center', gap: 44}}>
            <Img
              src={staticFile('app_icon.png')}
              style={{
                width: 190,
                height: 190,
                borderRadius: 44,
                boxShadow: '0 18px 44px rgba(28, 79, 72, 0.22)',
              }}
            />
            <div
              style={{
                fontSize: 86,
                fontWeight: 600,
                color: TEAL_DARK,
                letterSpacing: -1,
              }}
            >
              PawVault
            </div>
          </div>

          <div
            style={{
              marginTop: 86,
              fontSize: 196,
              lineHeight: 1.04,
              fontWeight: 700,
              color: TEAL_DARK,
              letterSpacing: -5,
            }}
          >
            Every record.
            <br />
            Every pet.
          </div>

          <div
            style={{
              marginTop: 62,
              fontSize: 82,
              lineHeight: 1.3,
              color: TEAL,
              maxWidth: 1560,
            }}
          >
            Vaccinations, vet visits and documents, kept together.
          </div>
        </div>

        <div
          style={{
            display: 'flex',
            flexDirection: 'row',
            alignItems: 'center',
          }}
        >
          {SHOTS.map((src, i) => (
            <Phone key={src} src={src} index={i} />
          ))}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
