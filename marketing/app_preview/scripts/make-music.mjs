// ---------------------------------------------------------------------------
// make-music.mjs
//
// Synthesizes an ORIGINAL, royalty-free, upbeat background music bed for the
// PawVault paid-social ad and writes it to public/ad_music.wav as 16-bit PCM.
//
// Nothing here is sampled or copied from any existing recording — every sample
// is generated from raw oscillators, so the result is free to use commercially.
//
// Musical design:
//   - Warm major-key (C major) pad (stacked sine + slight detune)
//   - Gentle plucked arpeggio (decaying sine + a touch of triangle harmonics)
//   - Soft kick drum (pitch-dropping sine + short noise transient)
//   - ~120 BPM, ~15.5s, 0.4s fade-in, ~1.0s fade-out
//
// Run:  node scripts/make-music.mjs
// ---------------------------------------------------------------------------
import {writeFileSync, mkdirSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {dirname, join} from 'node:path';

const SAMPLE_RATE = 44100;
const BPM = 120;
const BEAT = 60 / BPM; // seconds per beat (0.5s)
const DURATION = 15.5; // seconds
const N = Math.floor(SAMPLE_RATE * DURATION);

// Master buffer (mono, float)
const buf = new Float32Array(N);

// --- helpers ---------------------------------------------------------------
const TAU = Math.PI * 2;

// Equal-tempered note frequency. midi 69 = A4 = 440Hz.
const note = (midi) => 440 * Math.pow(2, (midi - 69) / 12);

// Add a tone with an ADSR-ish exponential envelope at a given start time.
function addTone(startSec, durSec, freq, gain, {detune = 0, harmonics = []} = {}) {
  const start = Math.floor(startSec * SAMPLE_RATE);
  const len = Math.floor(durSec * SAMPLE_RATE);
  const attack = Math.min(0.01 * SAMPLE_RATE, len * 0.2);
  for (let i = 0; i < len; i++) {
    const idx = start + i;
    if (idx < 0 || idx >= N) continue;
    const t = i / SAMPLE_RATE;
    // Envelope: quick attack, exponential decay
    let env;
    if (i < attack) env = i / attack;
    else env = Math.exp(-3.2 * (t - attack / SAMPLE_RATE) / durSec);
    let s = Math.sin(TAU * freq * t);
    if (detune) s += 0.6 * Math.sin(TAU * (freq * (1 + detune)) * t);
    for (const [mult, amp] of harmonics) {
      s += amp * Math.sin(TAU * freq * mult * t);
    }
    buf[idx] += s * env * gain;
  }
}

// Sustained pad chord that swells and holds across a region.
function addPad(startSec, durSec, midis, gain) {
  const start = Math.floor(startSec * SAMPLE_RATE);
  const len = Math.floor(durSec * SAMPLE_RATE);
  const swell = 0.6 * SAMPLE_RATE; // 0.6s swell in/out
  for (let i = 0; i < len; i++) {
    const idx = start + i;
    if (idx < 0 || idx >= N) continue;
    const t = i / SAMPLE_RATE;
    let env = 1;
    if (i < swell) env = i / swell;
    else if (i > len - swell) env = (len - i) / swell;
    // slow chorus shimmer
    const shimmer = 1 + 0.004 * Math.sin(TAU * 0.7 * t);
    let s = 0;
    for (const m of midis) {
      const f = note(m) * shimmer;
      s += Math.sin(TAU * f * t) + 0.5 * Math.sin(TAU * f * 1.001 * t);
    }
    s /= midis.length * 1.5;
    buf[idx] += s * env * gain;
  }
}

// Soft kick: pitch-dropping sine + tiny noise click.
function addKick(startSec, gain) {
  const start = Math.floor(startSec * SAMPLE_RATE);
  const len = Math.floor(0.18 * SAMPLE_RATE);
  for (let i = 0; i < len; i++) {
    const idx = start + i;
    if (idx < 0 || idx >= N) continue;
    const t = i / SAMPLE_RATE;
    const env = Math.exp(-22 * t);
    const f = 120 * Math.exp(-30 * t) + 48; // drop 120Hz -> 48Hz
    let s = Math.sin(TAU * f * t) * env;
    if (i < 0.006 * SAMPLE_RATE) s += (Math.random() * 2 - 1) * 0.25 * env;
    buf[idx] += s * gain;
  }
}

// --- arrangement -----------------------------------------------------------
// Chord progression (4 bars of 4 beats, looped): C - G - Am - F
// MIDI roots and pad voicings (major-key, warm, no minor-clash dissonance).
const chords = [
  {pad: [48, 55, 60, 64], arp: [60, 64, 67, 72]}, // C major
  {pad: [43, 55, 59, 62], arp: [55, 59, 62, 67]}, // G major
  {pad: [45, 57, 60, 64], arp: [57, 60, 64, 69]}, // A minor
  {pad: [41, 53, 57, 60], arp: [53, 57, 60, 65]}, // F major
];

const barLen = BEAT * 4; // 2.0s per bar
const totalBars = Math.ceil(DURATION / barLen); // ~8 bars

for (let bar = 0; bar < totalBars; bar++) {
  const ch = chords[bar % chords.length];
  const barStart = bar * barLen;

  // Pad swells over the bar.
  addPad(barStart, barLen, ch.pad, 0.16);

  // Kick on beats 1 and 3 (four-on-floor-lite).
  addKick(barStart + 0 * BEAT, 0.9);
  addKick(barStart + 2 * BEAT, 0.9);
  // light off-beat kick to keep energy from bar 2 onward
  if (bar >= 1) addKick(barStart + 3 * BEAT, 0.45);

  // Plucked arpeggio: eighth notes across the bar.
  const arp = ch.arp;
  for (let step = 0; step < 8; step++) {
    const t = barStart + step * (BEAT / 2);
    const n = arp[step % arp.length] + (step >= 4 ? 0 : 0);
    addTone(t, 0.42, note(n), 0.11, {
      harmonics: [
        [2, 0.18],
        [3, 0.07],
      ],
    });
  }

  // Sparkle high note on bar downbeat from bar 2 (adds "upbeat" lift).
  if (bar >= 1) addTone(barStart, 0.6, note(arp[arp.length - 1] + 12), 0.06);
}

// --- master fades + normalize ----------------------------------------------
const fadeIn = Math.floor(0.4 * SAMPLE_RATE);
const fadeOut = Math.floor(1.0 * SAMPLE_RATE);

// Find peak for normalization.
let peak = 0;
for (let i = 0; i < N; i++) peak = Math.max(peak, Math.abs(buf[i]));
const norm = peak > 0 ? 0.85 / peak : 1;

const pcm = Buffer.alloc(N * 2);
for (let i = 0; i < N; i++) {
  let s = buf[i] * norm;
  // fades
  if (i < fadeIn) s *= i / fadeIn;
  if (i > N - fadeOut) s *= (N - i) / fadeOut;
  // soft clip safety
  s = Math.max(-1, Math.min(1, s));
  pcm.writeInt16LE(Math.round(s * 32767), i * 2);
}

// --- WAV container ---------------------------------------------------------
function wavHeader(dataLen) {
  const h = Buffer.alloc(44);
  h.write('RIFF', 0);
  h.writeUInt32LE(36 + dataLen, 4);
  h.write('WAVE', 8);
  h.write('fmt ', 12);
  h.writeUInt32LE(16, 16); // PCM chunk size
  h.writeUInt16LE(1, 20); // PCM format
  h.writeUInt16LE(1, 22); // mono
  h.writeUInt32LE(SAMPLE_RATE, 24);
  h.writeUInt32LE(SAMPLE_RATE * 2, 28); // byte rate
  h.writeUInt16LE(2, 32); // block align
  h.writeUInt16LE(16, 34); // bits per sample
  h.write('data', 36);
  h.writeUInt32LE(dataLen, 40);
  return h;
}

const __dirname = dirname(fileURLToPath(import.meta.url));
const outDir = join(__dirname, '..', 'public');
mkdirSync(outDir, {recursive: true});
const outPath = join(outDir, 'ad_music.wav');
writeFileSync(outPath, Buffer.concat([wavHeader(pcm.length), pcm]));

console.log(
  `Wrote ${outPath} — ${DURATION}s, ${SAMPLE_RATE}Hz mono 16-bit PCM (${(
    pcm.length / 1024
  ).toFixed(0)} KB)`,
);
