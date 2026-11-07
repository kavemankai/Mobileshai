// Hidden object: find the listed items in a cluttered scene. Placeholder art uses emoji glyphs;
// the art pass replaces them with a painted scene and invisible tap regions at the same positions.

import { SCENE_ART } from '../assets/manifest';
import { placeholderSvg } from '../core/art';
import { h } from '../core/dom';
import { rng } from '../core/rng';
import type { HiddenDef, PuzzleMount } from '../core/types';

export interface HiddenSpot { id: string; x: number; y: number }

export function hiddenSpots(def: HiddenDef): HiddenSpot[] {
  const spots: HiddenSpot[] = [];
  for (const t of def.targets) {
    spots.push({ id: t.id, x: t.x, y: t.y });
    for (const [x, y] of def.extra?.[t.id] ?? []) spots.push({ id: t.id, x, y });
  }
  return spots;
}

export const mountHidden: PuzzleMount<HiddenDef> = (def, ctx) => {
  const rand = rng(ctx.seed);
  const spots = hiddenSpots(def);
  const need = new Map(def.targets.map((t) => [t.id, spots.filter((s) => s.id === t.id).length]));
  const got = new Map(def.targets.map((t) => [t.id, 0]));
  let done = false;

  const scene = h('div', { class: 'hidden-scene' });
  // Painted scene as a backdrop when available, dimmed so the items read. Not a hidden-object painting yet.
  const art = SCENE_ART[def.scene];
  if (art) scene.append(h('img', { class: 'ho-backdrop', src: art, alt: '', draggable: 'false' }));
  else scene.innerHTML = placeholderSvg(def.scene, 300, 400);

  // Clutter first, kept a little away from targets so targets are never fully covered.
  for (let n = 0, tries = 0; n < def.clutter && tries < def.clutter * 20; tries++) {
    const x = 4 + rand() * 92, y = 4 + rand() * 92;
    if (spots.some((s) => Math.hypot(s.x - x, (s.y - y) * 0.75) < 5)) continue;
    const g = def.clutterGlyphs[Math.floor(rand() * def.clutterGlyphs.length)];
    scene.append(h('span', {
      class: 'ho-clutter', 'aria-hidden': 'true', text: g,
      style: { left: `${x}%`, top: `${y}%`, transform: `translate(-50%,-50%) rotate(${Math.round(rand() * 70 - 35)}deg) scale(${(0.7 + rand() * 0.6).toFixed(2)})`, opacity: (0.55 + rand() * 0.4).toFixed(2) },
    }));
    n++;
  }

  const list = h('ul', { class: 'ho-list' });
  const rows = new Map<string, HTMLElement>();
  for (const t of def.targets) {
    const li = h('li', null, h('span', { class: 'ho-name', text: t.label }), h('span', { class: 'ho-count' }));
    rows.set(t.id, li);
    list.append(li);
  }
  const refresh = () => {
    for (const t of def.targets) {
      const li = rows.get(t.id)!;
      const n = need.get(t.id)!, g = got.get(t.id)!;
      li.querySelector('.ho-count')!.textContent = n > 1 ? `${g}/${n}` : g ? '✓' : '';
      li.classList.toggle('found', g >= n);
    }
  };

  spots.forEach((s, idx) => {
    const t = def.targets.find((x) => x.id === s.id)!;
    const el = h('button', {
      class: 'ho-target', 'aria-label': t.label, text: t.glyph, 'data-target': s.id, 'data-idx': idx,
      style: { left: `${s.x}%`, top: `${s.y}%`, transform: `translate(-50%,-50%) rotate(${Math.round(rand() * 50 - 25)}deg)` },
    });
    el.addEventListener('click', (e) => {
      e.stopPropagation();
      if (done || el.classList.contains('found')) return;
      el.classList.add('found');
      got.set(s.id, got.get(s.id)! + 1);
      ctx.sfx('found'); ctx.haptic();
      ctx.status(`Found: ${t.label}`);
      refresh();
      if ([...need].every(([id, n]) => got.get(id)! >= n)) { done = true; ctx.solved(); }
    });
    scene.append(el);
  });

  scene.addEventListener('click', (e) => {
    if (done) return;
    const r = scene.getBoundingClientRect();
    const ring = h('span', { class: 'ho-miss', style: { left: `${e.clientX - r.left}px`, top: `${e.clientY - r.top}px` } });
    scene.append(ring);
    setTimeout(() => ring.remove(), 500);
  });

  ctx.root.append(h('div', { class: 'board-frame hidden-frame' }, scene, list));
  refresh();
  ctx.status('Tap the items on the list. Missing costs nothing.');
  return {};
};
