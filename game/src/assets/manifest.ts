// Every swappable asset lives here. The art and sound pass only needs to touch this file and the
// folders next to it. Anything missing falls back to a generated placeholder, so the game always runs.
//
// Art:      scene backdrops are portrait 9:16 (1080x1920 source recommended). Put files in ./art and
//           map them below. Portraits go in ./portraits, half-body, transparent background.
// Audio:    put files in ./audio (m4a for iOS, or mp3) and map them to an SfxName in AUDIO_FILES.

import type { SceneKey } from '../core/types';

import exterior from './art/exterior.webp';
import exteriorTitle from './art/exterior_title.webp';
import reception from './art/reception.webp';
import security from './art/security.webp';
import room from './art/room.webp';
import service from './art/service-v2.webp';
import corridor17 from './art/corridor17-v2.webp';
import yard from './art/yard-v2.webp';
import records from './art/records-v2.webp';
import laundry from './art/laundry-v2.webp';
import nina from './portraits/nina.webp';
import claire from './portraits/claire.webp';
import owen from './portraits/owen.webp';
import daniel from './portraits/daniel.webp';

/** All nine locales have painted backdrops. Pass 02 fills the five previously unmapped scenes.
 * These are atmosphere plates, not aligned puzzle layers; keep room prop overlays enabled. */
export const SCENE_ART: Partial<Record<SceneKey, string>> = {
  exterior,
  reception,
  security,
  room17: room,
  service,
  corridor17,
  yard,
  records,
  laundry,
};

export const TITLE_ART: string | null = exteriorTitle;

/** Portraits by speaker name (first word of the speaker tag, upper case). */
export const PORTRAITS: Record<string, string> = {
  NINA: nina,
  CLAIRE: claire,
  OWEN: owen,
  DANIEL: daniel,
};

/** Recorded sound files by SfxName. Empty: every sound is synthesised. */
export const AUDIO_FILES: Record<string, string> = {};

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
