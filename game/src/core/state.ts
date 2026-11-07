// Save data and settings, both in localStorage. Every access is guarded: private mode or
// blocked storage must never break the game, it just stops remembering.

export const SAVE_KEY = 'last-check-in-save-v2';
export const SETTINGS_KEY = 'last-check-in-settings-v2';

export type Phase = 'name' | 'chapter' | 'intro' | 'puzzle' | 'reveal' | 'end';

export interface SaveData {
  v: 2;
  name: string;
  level: number;
  phase: Phase;
  line: number;
  /** Level indices whose clue has been earned. */
  clues: number[];
  hints: Record<number, number>;
  finished: boolean;
}

export interface Settings {
  master: number;
  music: number;
  ambience: number;
  effects: number;
  muted: boolean;
  reducedMotion: boolean;
  textSize: 1 | 2 | 3;
  haptics: boolean;
}

export function newSave(name = ''): SaveData {
  return { v: 2, name, level: 0, phase: 'name', line: 0, clues: [], hints: {}, finished: false };
}

export function loadSave(levelCount: number): SaveData | null {
  try {
    const raw = localStorage.getItem(SAVE_KEY);
    if (!raw) return null;
    const s = JSON.parse(raw) as SaveData;
    const phases: Phase[] = ['name', 'chapter', 'intro', 'puzzle', 'reveal', 'end'];
    if (s?.v !== 2 || !Number.isInteger(s.level) || s.level < 0 || s.level > levelCount || !phases.includes(s.phase) || !Array.isArray(s.clues)) return null;
    s.hints ||= {};
    s.name = typeof s.name === 'string' ? s.name.slice(0, 20) : '';
    return s;
  } catch {
    return null;
  }
}

export function writeSave(s: SaveData) {
  try { localStorage.setItem(SAVE_KEY, JSON.stringify(s)); } catch { /* storage unavailable */ }
}

export function clearSave() {
  try { localStorage.removeItem(SAVE_KEY); } catch { /* storage unavailable */ }
}

const prefersReduced = typeof matchMedia === 'function' && matchMedia('(prefers-reduced-motion: reduce)').matches;

export const settings: Settings = {
  master: 0.7, music: 0.35, ambience: 0.45, effects: 0.7,
  muted: false, reducedMotion: prefersReduced, textSize: 1, haptics: true,
};

try {
  Object.assign(settings, JSON.parse(localStorage.getItem(SETTINGS_KEY) || '{}'));
} catch { /* ignore */ }

export function saveSettings() {
  try { localStorage.setItem(SETTINGS_KEY, JSON.stringify(settings)); } catch { /* ignore */ }
}
