// Asset wiring: every mood tag has a portrait, every sound the code asks for has a file,
// every scene has art and room tone.

import { describe, expect, it } from 'vitest';
import { AMBIENCE_FILES, AUDIO_FILES, ITEM_ICONS, MATCH_TILES, MUSIC_FILES, PANEL_ART, PORTRAITS, SCENE_ART, STINGER_FILES } from '../src/assets/manifest';
import { parseSpeaker, portraitFor } from '../src/core/art';
import { LEVELS } from '../src/story/levels';

const SCENES = ['exterior', 'reception', 'security', 'service', 'corridor17', 'room17', 'yard', 'records', 'laundry'];
const SFX = ['tap', 'pick', 'place', 'invalid', 'solve', 'clue', 'power', 'door', 'paper', 'metal', 'click', 'static', 'phone', 'pour', 'clear', 'roll', 'ratchet', 'latch', 'chapter', 'swap', 'found', 'combo'];

describe('art', () => {
  it('maps every scene', () => SCENES.forEach((s) => expect(SCENE_ART[s as keyof typeof SCENE_ART], s).toBeTruthy()));
  it('has a portrait for every mood used in the script', () => {
    for (const l of LEVELS) for (const [speaker] of [...l.intro, ...l.reveal]) {
      const { name, mood } = parseSpeaker(speaker);
      if (!mood) continue;
      const key = `${name.split(/[ ·]/)[0].toUpperCase()}_${mood}`;
      expect(PORTRAITS[key], `${l.title}: ${speaker}`).toBeTruthy();
      expect(portraitFor(speaker)).toBe(PORTRAITS[key]);
    }
  });
  it('has a base portrait for each named character', () => ['NINA', 'CLAIRE', 'OWEN', 'DANIEL'].forEach((k) => expect(PORTRAITS[k]).toBeTruthy()));
  it('has an icon for every room item', () => {
    for (const l of LEVELS) if (l.puzzle.kind === 'room') Object.keys(l.puzzle.items).forEach((id) => expect(ITEM_ICONS[id], id).toBeTruthy());
  });
  it('has one match-3 tile per colour', () => {
    for (const l of LEVELS) if (l.puzzle.kind === 'match3') expect(MATCH_TILES.length).toBeGreaterThanOrEqual(l.puzzle.colors);
  });
  it('has CCTV art for both views of every level 4 frame', () => {
    const p = LEVELS[3].puzzle;
    if (p.kind !== 'panels') throw new Error('level 4 should be panels');
    p.panels.forEach((pn) => pn.views.forEach((v) => expect(PANEL_ART[`${pn.id}_${v.name}`], `${pn.id}_${v.name}`).toBeTruthy()));
  });
});

describe('audio', () => {
  it('has a file for every sound effect', () => SFX.forEach((n) => expect(AUDIO_FILES[n], n).toBeTruthy()));
  it('has room tone for every scene', () => SCENES.forEach((s) => expect(AMBIENCE_FILES[s], s).toBeTruthy()));
  it('has all five music cues and three stingers', () => {
    ['title', 'investigation', 'tension', 'pressure', 'resolution'].forEach((m) => expect(MUSIC_FILES[m], m).toBeTruthy());
    ['clue_found', 'chapter_end', 'nina_voice'].forEach((s) => expect(STINGER_FILES[s], s).toBeTruthy());
  });
});
