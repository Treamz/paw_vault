import {Composition} from 'remotion';
import {Montage, TOTAL_FRAMES} from './Montage';
import {Ad, AD_TOTAL_FRAMES} from './Ad';
import {AppPreview, APP_PREVIEW_TOTAL_FRAMES} from './AppPreview';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      {/*
        App Store APP PREVIEW (compliant, full-bleed). Each app screenshot fills
        the entire 886x1920 frame edge-to-edge — no device frame/border/radius/
        shadow/background — to satisfy Guideline 2.3.4. Kept separate from the
        social `Montage`/`MontageSquare` so those keep their framed look.
      */}
      <Composition
        id="AppPreview"
        component={AppPreview}
        durationInFrames={APP_PREVIEW_TOTAL_FRAMES}
        fps={30}
        width={886}
        height={1920}
      />
      <Composition
        id="Montage"
        component={Montage}
        durationInFrames={TOTAL_FRAMES}
        fps={30}
        width={886}
        height={1920}
        defaultProps={{square: false as boolean}}
      />
      <Composition
        id="MontageSquare"
        component={Montage}
        durationInFrames={TOTAL_FRAMES}
        fps={30}
        width={1080}
        height={1080}
        defaultProps={{square: true as boolean}}
      />
      {/* Paid-social ad creative (with audio) — separate from the montage. */}
      <Composition
        id="Ad"
        component={Ad}
        durationInFrames={AD_TOTAL_FRAMES}
        fps={30}
        width={1080}
        height={1920}
        defaultProps={{square: false as boolean}}
      />
      <Composition
        id="AdSquare"
        component={Ad}
        durationInFrames={AD_TOTAL_FRAMES}
        fps={30}
        width={1080}
        height={1080}
        defaultProps={{square: true as boolean}}
      />
      {/* Same ad, sized for the App Store App Preview slot (iPhone 886x1920). */}
      <Composition
        id="AdPreview"
        component={Ad}
        durationInFrames={AD_TOTAL_FRAMES}
        fps={30}
        width={886}
        height={1920}
        defaultProps={{square: false as boolean}}
      />
    </>
  );
};
