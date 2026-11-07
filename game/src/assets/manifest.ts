// Every swappable asset lives here. The art and sound pass only needs to touch this file and the
// folders next to it. Anything missing falls back to a generated placeholder, so the game always runs.
//
// Art:      scene backdrops are portrait 9:16 (1080x1920 source recommended). Put files in ./art and
//           map them below. Portraits go in ./portraits, transparent background.
// Audio:    drop m4a files into ./audio/{sfx,ambience,music,stingers}. They are picked up by file name:
//           sfx/<SfxName>.m4a, ambience/<SceneKey>.m4a, music/<MusicCue>.m4a, stingers/<Stinger>.m4a.
//
// Status (7 Nov 2026): WIP pack integrated. See ASSETS.md for what is final, draft or still missing.

import type { SceneKey } from '../core/types';

// Scenes. Five v2 paintings (environment pass 02) plus five WIP plates from the asset zips.
// The WIP plates are enlarged from a reference board: soft, with a blurred lower third. Replace them first.
import exterior from './art/exterior-wip.webp';
import exteriorTitle from './art/exterior_title-wip.webp';
import reception from './art/reception-wip.webp';
import security from './art/security-wip.webp';
import room17 from './art/room17-wip.webp';
import service from './art/service-v2.webp';
import corridor17 from './art/corridor17-v2.webp';
import yard from './art/yard-v2.webp';
import records from './art/records-v2.webp';
import laundry from './art/laundry-v2.webp';

// Portraits. Nina and Claire have WIP expression cutouts; Owen and Daniel keep the first-pass crops
// because their WIP expressions have defects (sliced heads, Daniel's has text baked into the image).
import ninaNeutral from './portraits/nina_neutral.webp';
import ninaFrightened from './portraits/nina_frightened.webp';
import ninaRelieved from './portraits/nina_relieved.webp';
import claireGuarded from './portraits/claire_guarded.webp';
import claireGrieving from './portraits/claire_grieving.webp';
import claireAngry from './portraits/claire_angry.webp';
import owen from './portraits/owen.webp';
import daniel from './portraits/daniel.webp';

import torch from './inventory/torch.png';
import screwdriver from './inventory/screwdriver.png';
import coin from './inventory/coin_50c.png';
import gloves from './inventory/gloves.png';

import tile1 from './puzzles/match_tile_1.png';
import tile2 from './puzzles/match_tile_2.png';
import tile3 from './puzzles/match_tile_3.png';
import tile4 from './puzzles/match_tile_4.png';
import tile5 from './puzzles/match_tile_5.png';

import cctv01w from './cctv/panel_01_wide.webp';
import cctv01c from './cctv/panel_01_close.webp';
import cctv02w from './cctv/panel_02_wide.webp';
import cctv02c from './cctv/panel_02_close.webp';
import cctv05w from './cctv/panel_05_wide.webp';
import cctv05c from './cctv/panel_05_close.webp';
import cctv06w from './cctv/panel_06_wide.webp';
import cctv06c from './cctv/panel_06_close.webp';

export const SCENE_ART: Partial<Record<SceneKey, string>> = {
  exterior, reception, security, room17, service, corridor17, yard, records, laundry,
};

export const TITLE_ART: string | null = exteriorTitle;

/**
 * Portraits. Key is the speaker's first word, optionally with a mood: NINA, NINA_FRIGHTENED.
 * Script lines pick a mood with `~`: 'NINA~frightened|...'. A missing mood falls back to the base key.
 */
export const PORTRAITS: Record<string, string> = {
  NINA: ninaNeutral,
  NINA_NEUTRAL: ninaNeutral,
  NINA_FRIGHTENED: ninaFrightened,
  NINA_RELIEVED: ninaRelieved,
  CLAIRE: claireGuarded,
  CLAIRE_GUARDED: claireGuarded,
  CLAIRE_GRIEVING: claireGrieving,
  CLAIRE_ANGRY: claireAngry,
  OWEN: owen,
  DANIEL: daniel,
};

/** Portraits that are transparent cutouts (no edge fade needed). */
export const CUTOUT_PORTRAITS = new Set([ninaNeutral, ninaFrightened, ninaRelieved, claireGuarded, claireGrieving, claireAngry]);

/** Inventory icons by item id (room puzzles). Missing ids use the emoji in levels.ts. */
export const ITEM_ICONS: Record<string, string> = { torch, screwdriver, coin, gloves };

/** Match-3 tile sprites, one per colour index. */
export const MATCH_TILES: string[] = [tile1, tile2, tile3, tile4, tile5];

/** CCTV footage behind the frames puzzle, by `${panelId}_${viewName}`. Level 4 only for now. */
export const PANEL_ART: Record<string, string> = {
  a_wide: cctv02w, a_close: cctv02c,
  b_wide: cctv01w, b_close: cctv01c,
  c_wide: cctv05w, c_close: cctv05c,
  d_wide: cctv06w, d_close: cctv06c,
};

const pick = (g: Record<string, unknown>): Record<string, string> =>
  Object.fromEntries(Object.entries(g).map(([path, url]) => [path.split('/').pop()!.replace(/\.\w+$/, ''), url as string]));

/** Sound effects by SfxName. */
export const AUDIO_FILES = pick(import.meta.glob('./audio/sfx/*.m4a', { eager: true, query: '?url', import: 'default' }));
/** Looping room tone by SceneKey. */
export const AMBIENCE_FILES = pick(import.meta.glob('./audio/ambience/*.m4a', { eager: true, query: '?url', import: 'default' }));
/** Looping score cues: title, investigation, tension, pressure, resolution. */
export const MUSIC_FILES = pick(import.meta.glob('./audio/music/*.m4a', { eager: true, query: '?url', import: 'default' }));
/** One-shot stingers: clue_found, chapter_end, nina_voice. */
export const STINGER_FILES = pick(import.meta.glob('./audio/stingers/*.m4a', { eager: true, query: '?url', import: 'default' }));

/** Placeholder palette per scene, used when no art is mapped. */
export const SCENE_PLACEHOLDER: Record<SceneKey, { label: string; top: string; bottom: string; accent: string }> = {
  exterior: { label: 'MARINER MOTEL · EXTERIOR', top: '#0e2230', bottom: '#050b10', accent: '#e8b877' },
  reception: { label: 'RECEPTION', top: '#2a2216', bottom: '#0b1018', accent: '#e8b877' },
  security: { label: 'SECURITY OFFICE', top: '#10262c', bottom: '#060c10', accent: '#7fb7ad' },
  service: { label: 'SERVICE CORRIDOR', top: '#1b2427', bottom: '#080b0d', accent: '#b9c4b0' },
  corridor17: { label: 'CORRIDOR · ROOM 17', top: '#231c22', bottom: '#09080c', accent: '#d8a36a' },
  room17: { label: 'ROOM 17', top: '#2b1f19', bottom: '#0c0907', accent: '#e8b877' },
  yard: { label: 'REAR SERVICE YARD', top: '#0f1d26', bottom: '#04080b', accent: '#9dbcb8' },
  records: { label: 'RECORDS OFFICE', top: '#241f17', bottom: '#0a0907', accent: '#d9c5a4' },
  laundry: { label: 'DISUSED LAUNDRY', top: '#2a1712', bottom: '#0b0605', accent: '#d9734e' },
};
