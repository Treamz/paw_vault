import {Composition} from 'remotion';
import {Montage, TOTAL_FRAMES} from './Montage';

export const RemotionRoot: React.FC = () => {
  return (
    <>
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
    </>
  );
};
