// Audio: four buses (master, music, ambience, effects).
// Files from src/assets/audio are used when present; every sound also has a synthesised fallback,
// so a missing or undecodable file never leaves the game silent.
//
// Effects and stingers are decoded once, up front (they are tiny). Music and ambience loops are
// decoded on demand and only the most recent few are kept in memory, which matters on phones.

import { AMBIENCE_FILES, AUDIO_FILES, MUSIC_FILES, STINGER_FILES } from '../assets/manifest';
import { settings } from './state';
import type { SceneKey, SfxName } from './types';

type Bus = 'master' | 'music' | 'ambience' | 'effects';
export type MusicCue = 'title' | 'investigation' | 'tension' | 'pressure' | 'resolution';
export type Stinger = 'clue_found' | 'chapter_end' | 'nina_voice';

interface Loop { key: string; src: AudioBufferSourceNode; gain: GainNode }

interface Engine {
  ctx: AudioContext;
  buses: Record<Bus, GainNode>;
  duck: GainNode;
  synthAmb: GainNode;
  synthPads: GainNode;
  weather: BiquadFilterNode;
  pads: OscillatorNode[];
  loops: { music: Loop | null; ambience: Loop | null };
}

const FADE = 1.6; // seconds for loop crossfades
const FILE_GAIN = { effects: 0.8, music: 0.9, ambience: 0.9, stinger: 0.85 };
const LONG_CACHE = 4; // decoded music/ambience buffers kept in memory

let eng: Engine | null = null;
const buffers = new Map<string, Promise<AudioBuffer | null>>(); // by url
const longOrder: string[] = [];
const ready = new Map<string, AudioBuffer>(); // decoded sfx/stingers by url
const want: { music: string | null; ambience: string | null } = { music: null, ambience: null };
const req = { music: 0, ambience: 0 };
let synthScene: SceneKey | '' = '';
let synthChapter = -1;

function decode(url: string, long: boolean): Promise<AudioBuffer | null> {
  if (!eng) return Promise.resolve(null);
  let p = buffers.get(url);
  if (!p) {
    const ctx = eng.ctx;
    p = fetch(url).then((r) => r.arrayBuffer()).then((b) => ctx.decodeAudioData(b)).catch(() => null);
    buffers.set(url, p);
  }
  if (long) {
    const i = longOrder.indexOf(url);
    if (i >= 0) longOrder.splice(i, 1);
    longOrder.push(url);
    while (longOrder.length > LONG_CACHE) {
      const old = longOrder.shift()!;
      if (old !== eng.loops.music?.key && old !== eng.loops.ambience?.key) buffers.delete(old);
    }
  }
  return p;
}

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

      // Synth fallback ambience: looped brown noise through a per-room low-pass filter.
      const buf = ctx.createBuffer(1, ctx.sampleRate * 3, ctx.sampleRate);
      const d = buf.getChannelData(0);
      let b = 0;
      for (let i = 0; i < d.length; i++) { b = (b + Math.random() * 0.04 - 0.02) / 1.02; d[i] = b * 2; }
      const noise = ctx.createBufferSource();
      noise.buffer = buf; noise.loop = true;
      const weather = ctx.createBiquadFilter();
      weather.type = 'lowpass'; weather.frequency.value = 1200;
      const synthAmb = mk(); synthAmb.gain.value = 0;
      noise.connect(weather).connect(synthAmb).connect(buses.ambience);
      noise.start();

      // Synth fallback score: four slow-beating sine pads.
      const synthPads = mk(); synthPads.gain.value = 0;
      synthPads.connect(buses.music);
      const pads: OscillatorNode[] = [];
      [55, 82.41, 110, 146.83].forEach((f, i) => {
        const o = ctx.createOscillator(), v = mk(), lfo = ctx.createOscillator(), depth = mk();
        o.type = 'sine'; o.frequency.value = f; v.gain.value = 0.025;
        lfo.frequency.value = 0.045 + i * 0.018; depth.gain.value = 0.013;
        lfo.connect(depth).connect(v.gain); o.connect(v).connect(synthPads);
        o.start(); lfo.start(); pads.push(o);
      });
      eng = { ctx, buses, duck, synthAmb, synthPads, weather, pads, loops: { music: null, ambience: null } };
      mix();
      for (const url of [...Object.values(AUDIO_FILES), ...Object.values(STINGER_FILES)]) {
        void decode(url, false).then((b) => { if (b) ready.set(url, b); });
      }
      // Start whatever the game asked for before the first tap.
      const m = want.music, a = want.ambience;
      want.music = want.ambience = null;
      if (m) playLoop('music', m);
      if (a) playLoop('ambience', a);
    }
    if (eng.ctx.state === 'suspended' && !document.hidden) void eng.ctx.resume();
  } catch { /* audio unavailable */ }
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

function synthLayer(kind: 'music' | 'ambience', on: boolean) {
  if (!eng) return;
  const g = kind === 'music' ? eng.synthPads : eng.synthAmb;
  g.gain.setTargetAtTime(on ? (kind === 'music' ? 1 : 0.55) : 0, eng.ctx.currentTime, FADE / 3);
}

/** Crossfade a looping track. `key` is the file name in the manifest; unknown keys use the synth layer. */
function playLoop(kind: 'music' | 'ambience', key: string) {
  if (!eng) { want[kind] = key; return; }
  const files = kind === 'music' ? MUSIC_FILES : AMBIENCE_FILES;
  const url = files[key];
  const cur = eng.loops[kind];
  if (cur?.key === url && url) return;
  const id = ++req[kind];
  const fadeOut = () => {
    const c = eng!.loops[kind];
    if (!c) return;
    const t = eng!.ctx.currentTime;
    c.gain.gain.cancelScheduledValues(t);
    c.gain.gain.setValueAtTime(c.gain.gain.value, t);
    c.gain.gain.linearRampToValueAtTime(0, t + FADE);
    c.src.stop(t + FADE + 0.05);
    eng!.loops[kind] = null;
  };
  if (!url) { fadeOut(); synthLayer(kind, true); return; }
  void decode(url, true).then((buf) => {
    if (!eng || id !== req[kind]) return; // superseded by a newer request
    fadeOut();
    if (!buf) { synthLayer(kind, true); return; }
    synthLayer(kind, false);
    const { ctx } = eng;
    const src = ctx.createBufferSource();
    src.buffer = buf; src.loop = true;
    const gain = ctx.createGain();
    gain.gain.setValueAtTime(0, ctx.currentTime);
    gain.gain.linearRampToValueAtTime(FILE_GAIN[kind], ctx.currentTime + FADE);
    src.connect(gain).connect(eng.buses[kind]);
    src.start();
    eng.loops[kind] = { key: url, src, gain };
  });
}

export function musicCue(cue: MusicCue) { playLoop('music', cue); }

const CUTOFF: Record<SceneKey, number> = {
  exterior: 2200, yard: 1900, room17: 750, corridor17: 900, security: 450, service: 1050, laundry: 650, records: 320, reception: 950,
};

/** Sets room tone for a scene and the score for the chapter. */
export function audioScene(s: SceneKey, ch: number, ending = false) {
  playLoop('ambience', s);
  musicCue(ending ? 'resolution' : ch <= 1 ? 'investigation' : ch === 2 ? 'tension' : 'pressure');
  if (!eng || (s === synthScene && ch === synthChapter)) return;
  synthScene = s; synthChapter = ch;
  const now = eng.ctx.currentTime;
  eng.weather.frequency.setTargetAtTime(CUTOFF[s] ?? 700, now, 1.5);
  const base = ending ? [65.41, 98, 130.81, 164.81] : [55, 82.41, 110, 146.83];
  const lift = ch === 3 && !ending ? 1.05946 : 1;
  eng.pads.forEach((o, i) => o.frequency.setTargetAtTime(base[i] * lift, now, 2));
}

/** Title screen: exterior rain and the title theme. */
export function audioTitle() {
  playLoop('ambience', 'exterior');
  musicCue('title');
}

function playBuffer(buf: AudioBuffer, gain: number) {
  const { ctx, buses } = eng!;
  const src = ctx.createBufferSource();
  const g = ctx.createGain();
  g.gain.value = gain;
  src.buffer = buf;
  src.connect(g).connect(buses.effects);
  src.start();
}

/** Plays a stinger. Returns false if the file isn't available, so callers can fall back to an sfx. */
export function stinger(name: Stinger): boolean {
  unlockAudio();
  if (!eng || settings.muted) return true;
  const url = STINGER_FILES[name];
  const buf = url ? ready.get(url) : undefined;
  if (!buf) return false;
  playBuffer(buf, FILE_GAIN.stinger);
  return true;
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
  const url = AUDIO_FILES[name];
  const file = url ? ready.get(url) : undefined;
  if (file) { playBuffer(file, FILE_GAIN.effects); return; }
  const { ctx, buses } = eng;
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

/** For tests and the debug panel. */
export function audioStatus() {
  const name = (url?: string) => (url ? Object.entries({ ...MUSIC_FILES, ...AMBIENCE_FILES }).find(([, u]) => u === url)?.[0] ?? '?' : null);
  return {
    unlocked: !!eng,
    state: eng?.ctx.state ?? 'none',
    music: name(eng?.loops.music?.key),
    ambience: name(eng?.loops.ambience?.key),
    effectsDecoded: [...ready.keys()].filter((u) => Object.values(AUDIO_FILES).includes(u)).length,
    stingersDecoded: [...ready.keys()].filter((u) => Object.values(STINGER_FILES).includes(u)).length,
    files: { sfx: Object.keys(AUDIO_FILES).length, ambience: Object.keys(AMBIENCE_FILES).length, music: Object.keys(MUSIC_FILES).length, stingers: Object.keys(STINGER_FILES).length },
  };
}

document.addEventListener('visibilitychange', () => {
  if (!eng) return;
  if (document.hidden) void eng.ctx.suspend();
  else void eng.ctx.resume();
});
