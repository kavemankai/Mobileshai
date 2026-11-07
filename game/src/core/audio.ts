// Audio: four buses (master, music, ambience, effects). Every sound has a synthesised placeholder.
// During the sound pass, drop files into src/assets/audio and register them in assets/manifest.ts;
// a registered file always wins over the synth fallback.

import { settings } from './state';
import type { SceneKey, SfxName } from './types';
import { AUDIO_FILES } from '../assets/manifest';

type Bus = 'master' | 'music' | 'ambience' | 'effects';

interface Engine {
  ctx: AudioContext;
  buses: Record<Bus, GainNode>;
  duck: GainNode;
  weather: BiquadFilterNode;
  pads: OscillatorNode[];
  buffers: Map<string, AudioBuffer>;
}

let eng: Engine | null = null;
let scene: SceneKey | '' = '';
let chapter = -1;

export function unlockAudio() {
  try {
    if (!eng) {
      const C = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (!C) return;
      const ctx = new C();
      const mk = () => ctx.createGain();
      const buses = { master: mk(), music: mk(), ambience: mk(), effects: mk() } as Record<Bus, GainNode>;
      const duck = mk();
      buses.master.connect(ctx.destination);
      buses.music.connect(duck).connect(buses.master);
      buses.ambience.connect(buses.master);
      buses.effects.connect(buses.master);

      // Placeholder ambience: looped brown noise through a low-pass filter whose cutoff changes per room.
      const buf = ctx.createBuffer(1, ctx.sampleRate * 3, ctx.sampleRate);
      const d = buf.getChannelData(0);
      let b = 0;
      for (let i = 0; i < d.length; i++) { b = (b + Math.random() * 0.04 - 0.02) / 1.02; d[i] = b * 2; }
      const noise = ctx.createBufferSource();
      noise.buffer = buf; noise.loop = true;
      const weather = ctx.createBiquadFilter();
      weather.type = 'lowpass'; weather.frequency.value = 1200;
      const ng = mk(); ng.gain.value = 0.55;
      noise.connect(weather).connect(ng).connect(buses.ambience);
      noise.start();

      // Placeholder score: four slow-beating sine pads.
      const pads: OscillatorNode[] = [];
      [55, 82.41, 110, 146.83].forEach((f, i) => {
        const o = ctx.createOscillator(), v = mk(), lfo = ctx.createOscillator(), depth = mk();
        o.type = 'sine'; o.frequency.value = f; v.gain.value = 0.025;
        lfo.frequency.value = 0.045 + i * 0.018; depth.gain.value = 0.013;
        lfo.connect(depth).connect(v.gain); o.connect(v).connect(buses.music);
        o.start(); lfo.start(); pads.push(o);
      });
      eng = { ctx, buses, duck, weather, pads, buffers: new Map() };
      mix();
      void loadFiles();
    }
    if (eng.ctx.state === 'suspended' && !document.hidden) void eng.ctx.resume();
  } catch { /* audio unavailable */ }
}

async function loadFiles() {
  if (!eng) return;
  for (const [name, url] of Object.entries(AUDIO_FILES)) {
    try {
      const res = await fetch(url);
      eng.buffers.set(name, await eng.ctx.decodeAudioData(await res.arrayBuffer()));
    } catch { /* fall back to synth */ }
  }
}

export function mix() {
  if (!eng) return;
  const now = eng.ctx.currentTime;
  const set = (bus: Bus, v: number) => eng!.buses[bus].gain.setTargetAtTime(v, now, 0.12);
  set('master', settings.muted ? 0 : settings.master);
  set('music', settings.music);
  set('ambience', settings.ambience);
  set('effects', settings.effects);
}

/** Lower the music under dialogue, restore it for puzzles. */
export function duckMusic(on: boolean) {
  if (!eng) return;
  eng.duck.gain.setTargetAtTime(on ? 0.55 : 1, eng.ctx.currentTime, 0.4);
}

const CUTOFF: Record<SceneKey, number> = {
  exterior: 2200, yard: 1900, room17: 750, corridor17: 900, security: 450, service: 1050, laundry: 650, records: 320, reception: 950,
};

export function audioScene(s: SceneKey, ch: number, ending = false) {
  if (!eng || (s === scene && ch === chapter)) return;
  scene = s; chapter = ch;
  const now = eng.ctx.currentTime;
  eng.weather.frequency.setTargetAtTime(CUTOFF[s] ?? 700, now, 1.5);
  const base = ending ? [65.41, 98, 130.81, 164.81] : [55, 82.41, 110, 146.83];
  const lift = ch === 3 && !ending ? 1.05946 : 1;
  eng.pads.forEach((o, i) => o.frequency.setTargetAtTime(base[i] * lift, now, 2));
}

type Spec = [freq: number, dur: number, type: OscillatorType, slideTo?: number, noise?: boolean];
const SYNTH: Record<SfxName, Spec[]> = {
  tap: [[320, 0.06, 'sine']],
  pick: [[520, 0.05, 'triangle', 640]],
  place: [[260, 0.08, 'triangle', 200]],
  swap: [[420, 0.06, 'triangle', 520]],
  invalid: [[150, 0.16, 'sawtooth', 110]],
  solve: [[523, 0.12, 'triangle'], [659, 0.12, 'triangle'], [784, 0.22, 'triangle']],
  clue: [[392, 0.18, 'sine'], [587, 0.32, 'sine']],
  power: [[90, 0.5, 'sawtooth', 220]],
  door: [[110, 0.25, 'square', 70]],
  paper: [[2000, 0.09, 'sine', 900, true]],
  metal: [[880, 0.2, 'square', 820]],
  click: [[1400, 0.03, 'square']],
  static: [[3000, 0.3, 'sine', 3000, true]],
  phone: [[440, 0.18, 'sine'], [480, 0.18, 'sine']],
  pour: [[700, 0.35, 'sine', 300, true]],
  clear: [[660, 0.1, 'triangle', 990]],
  roll: [[180, 0.18, 'triangle', 120]],
  ratchet: [[1200, 0.04, 'square'], [1100, 0.04, 'square'], [1000, 0.04, 'square']],
  latch: [[300, 0.06, 'square', 180], [90, 0.12, 'square']],
  chapter: [[110, 0.9, 'sine', 82]],
  found: [[740, 0.1, 'sine', 990]],
  combo: [[660, 0.08, 'triangle'], [880, 0.08, 'triangle'], [1100, 0.12, 'triangle']],
};

export function sfx(name: SfxName) {
  unlockAudio();
  if (!eng || settings.muted) return;
  const { ctx, buses, buffers } = eng;
  const file = buffers.get(name);
  if (file) {
    const src = ctx.createBufferSource();
    src.buffer = file; src.connect(buses.effects); src.start();
    return;
  }
  let t = ctx.currentTime;
  for (const [f, dur, type, slide, noisy] of SYNTH[name]) {
    const g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(noisy ? 0.12 : 0.2, t + 0.01);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    g.connect(buses.effects);
    if (noisy) {
      const len = Math.ceil(ctx.sampleRate * dur);
      const b = ctx.createBuffer(1, len, ctx.sampleRate), d = b.getChannelData(0);
      for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
      const src = ctx.createBufferSource(); src.buffer = b;
      const flt = ctx.createBiquadFilter(); flt.type = 'bandpass'; flt.frequency.setValueAtTime(f, t);
      if (slide) flt.frequency.exponentialRampToValueAtTime(slide, t + dur);
      src.connect(flt).connect(g); src.start(t); src.stop(t + dur);
    } else {
      const o = ctx.createOscillator(); o.type = type;
      o.frequency.setValueAtTime(f, t);
      if (slide) o.frequency.exponentialRampToValueAtTime(slide, t + dur);
      o.connect(g); o.start(t); o.stop(t + dur + 0.02);
    }
    t += dur * 0.7;
  }
}

export function haptic(ms = 12) {
  if (!settings.haptics) return;
  try { navigator.vibrate?.(ms); } catch { /* unsupported */ }
}

document.addEventListener('visibilitychange', () => {
  if (!eng) return;
  if (document.hidden) void eng.ctx.suspend();
  else void eng.ctx.resume();
});
