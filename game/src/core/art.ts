// Scene backdrops and portraits, with generated placeholders where no art is mapped yet.

import { CUTOUT_PORTRAITS, PORTRAITS, SCENE_ART, SCENE_PLACEHOLDER } from '../assets/manifest';
import { h } from './dom';
import type { SceneKey } from './types';

export function placeholderSvg(key: SceneKey, w = 390, ht = 300): string {
  const p = SCENE_PLACEHOLDER[key];
  const rain = Array.from({ length: 26 }, (_, i) => {
    const x = (i * 53) % w, y = (i * 37) % ht;
    return `<path d="M${x} ${y}l-6 26" stroke="${p.accent}" stroke-opacity=".18" stroke-width="1"/>`;
  }).join('');
  return `<svg viewBox="0 0 ${w} ${ht}" preserveAspectRatio="xMidYMid slice" role="img" aria-label="${p.label} (placeholder art)">
    <defs><linearGradient id="g-${key}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${p.top}"/><stop offset="1" stop-color="${p.bottom}"/></linearGradient>
    <radialGradient id="l-${key}" cx=".7" cy=".35" r=".5"><stop offset="0" stop-color="${p.accent}" stop-opacity=".28"/><stop offset="1" stop-color="${p.accent}" stop-opacity="0"/></radialGradient></defs>
    <rect width="${w}" height="${ht}" fill="url(#g-${key})"/><rect width="${w}" height="${ht}" fill="url(#l-${key})"/>
    <path d="M0 ${ht * 0.72}H${w}" stroke="${p.accent}" stroke-opacity=".25"/>
    <rect x="${w * 0.12}" y="${ht * 0.3}" width="${w * 0.22}" height="${ht * 0.42}" fill="none" stroke="${p.accent}" stroke-opacity=".25"/>
    <rect x="${w * 0.55}" y="${ht * 0.45}" width="${w * 0.33}" height="${ht * 0.27}" fill="none" stroke="${p.accent}" stroke-opacity=".25"/>
    ${rain}
    <text x="16" y="${ht - 16}" fill="${p.accent}" fill-opacity=".6" font-family="ui-monospace,monospace" font-size="11" letter-spacing="2">${p.label} · PLACEHOLDER</text>
  </svg>`;
}

export function sceneArt(key: SceneKey, cls = 'scene-art'): HTMLElement {
  const url = SCENE_ART[key];
  const box = h('div', { class: cls, 'data-scene': key });
  if (url) {
    box.append(h('img', { src: url, alt: SCENE_PLACEHOLDER[key].label, draggable: 'false' }));
  } else {
    box.innerHTML = placeholderSvg(key);
  }
  box.append(h('div', { class: 'rain', 'aria-hidden': 'true' }));
  return box;
}

/** Speaker tags may carry a mood after `~`: 'NINA~frightened', 'CLAIRE · PHONE~angry'. */
export function parseSpeaker(speaker: string): { name: string; mood: string | null } {
  const [name, mood] = speaker.split('~');
  return { name: name.trim(), mood: mood ? mood.trim().toUpperCase() : null };
}

export const speakerName = (speaker: string) => parseSpeaker(speaker).name;

export function portraitFor(speaker: string): string | null {
  const { name, mood } = parseSpeaker(speaker);
  const key = name.split(/[ ·]/)[0].toUpperCase();
  return (mood && PORTRAITS[`${key}_${mood}`]) || PORTRAITS[key] || null;
}

export const isCutout = (url: string) => CUTOUT_PORTRAITS.has(url);
