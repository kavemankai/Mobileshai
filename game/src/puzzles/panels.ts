// Gorogoa-style panels: swap panels and switch each between wide and close views until one
// continuous path runs through every frame, in story order.

import { PANEL_ART } from '../assets/manifest';
import { h } from '../core/dom';
import { rng, shuffle } from '../core/rng';
import type { Edge, PanelsDef, PuzzleMount } from '../core/types';

export interface PanelsState { slots: number[]; views: number[] } // slots[slot] = panel index; views[panel] = 0|1

const OPP: Record<Edge, Edge> = { N: 'S', S: 'N', E: 'W', W: 'E' };

/** Follows the path. Returns visited panel indices in order, or null if it breaks or never reaches the end. */
export function tracePanels(def: PanelsDef, st: PanelsState): number[] | null {
  let slot = def.start.slot, entry = def.start.edge;
  const seen: number[] = [];
  for (let step = 0; step < def.rows * def.cols; step++) {
    const pi = st.slots[slot];
    const exits = def.panels[pi].views[st.views[pi]].exits;
    if (!exits.includes(entry)) return null;
    const out = exits[0] === entry ? exits[1] : exits[0];
    seen.push(pi);
    if (slot === def.end.slot && out === def.end.edge) return seen;
    const r = Math.floor(slot / def.cols), c = slot % def.cols;
    const [nr, nc] = out === 'N' ? [r - 1, c] : out === 'S' ? [r + 1, c] : out === 'E' ? [r, c + 1] : [r, c - 1];
    if (nr < 0 || nc < 0 || nr >= def.rows || nc >= def.cols) return null;
    slot = nr * def.cols + nc;
    entry = OPP[out];
    if (seen.includes(st.slots[slot])) return null;
  }
  return null;
}

export function panelsSolved(def: PanelsDef, st: PanelsState): boolean {
  const seen = tracePanels(def, st);
  return !!seen && seen.length === def.panels.length && seen.every((pi, i) => def.panels[pi].id === def.order[i]);
}

const EDGE_PT: Record<Edge, [number, number]> = { N: [50, 0], S: [50, 100], E: [100, 50], W: [0, 50] };

function panelSvg(exits: [Edge, Edge], caption: string, label: string, lit: boolean, art?: string): string {
  const [a, b] = exits.map((e) => EDGE_PT[e]);
  const d = `M${a[0]} ${a[1]} Q50 50 ${b[0]} ${b[1]}`;
  return `<svg viewBox="0 0 100 100" aria-hidden="true">
    <rect width="100" height="100" fill="#10232a"/>
    ${art ? `<image href="${art}" width="100" height="100" preserveAspectRatio="xMidYMid slice" opacity=".6"/><rect width="100" height="100" fill="#0b1520" opacity=".25"/>` : '<path d="M0 72H100" stroke="#2c4a50" stroke-width="1"/>'}
    <path d="${d}" stroke="${lit ? '#f2c77f' : '#7fb7ad'}" stroke-width="${lit ? 5 : 3}" fill="none" stroke-linecap="round" stroke-dasharray="${lit ? '0' : '6 4'}"/>
    ${exits.map((e) => `<circle cx="${EDGE_PT[e][0]}" cy="${EDGE_PT[e][1]}" r="5" fill="#e8b877"/>`).join('')}
    <text x="6" y="12" font-size="8" fill="#e8b877" font-family="ui-monospace,monospace">${label}</text>
    <text x="6" y="94" font-size="7" fill="#c9d6d1" font-family="ui-monospace,monospace">${caption}</text>
  </svg>`;
}

export const mountPanels: PuzzleMount<PanelsDef> = (def, ctx) => {
  const rand = rng(ctx.seed);
  const n = def.panels.length;
  let st: PanelsState;
  do {
    st = { slots: shuffle([...Array(n).keys()], rand), views: def.panels.map(() => (rand() < 0.5 ? 0 : 1)) };
  } while (tracePanels(def, st));
  let selected: number | null = null;
  let done = false;

  const grid = h('div', { class: 'panels-grid', style: { gridTemplateColumns: `repeat(${def.cols}, 1fr)` } });
  const draw = () => {
    grid.innerHTML = '';
    const lit = new Set(tracePanels(def, st) ?? partial());
    for (let s = 0; s < n; s++) {
      const pi = st.slots[s];
      const p = def.panels[pi], v = p.views[st.views[pi]];
      const card = h('div', { class: `panel-card${selected === s ? ' selected' : ''}${lit.has(pi) ? ' lit' : ''}` });
      if (s === def.start.slot) card.classList.add(`start-${def.start.edge}`);
      if (s === def.end.slot) card.classList.add(`end-${def.end.edge}`);
      const face = h('button', { class: 'panel-face', 'aria-label': `${p.label}, ${v.name} view. Tap to select, tap another panel to swap.`, html: panelSvg(v.exits, v.caption, p.label, lit.has(pi), PANEL_ART[`${p.id}_${v.name}`]) });
      face.addEventListener('click', () => pick(s));
      const zoom = h('button', { class: 'panel-zoom', text: v.name === 'wide' ? 'Zoom in' : 'Zoom out', 'aria-label': `Switch ${p.label} view` });
      zoom.addEventListener('click', () => { if (done) return; st.views[pi] ^= 1; ctx.sfx('click'); after(); });
      card.append(face, zoom);
      grid.append(card);
    }
  };
  // Panels lit from the start until the first break, so the player sees progress.
  const partial = (): number[] => {
    const out: number[] = [];
    let slot = def.start.slot, entry = def.start.edge;
    for (let k = 0; k < n; k++) {
      const pi = st.slots[slot];
      const ex = def.panels[pi].views[st.views[pi]].exits;
      if (!ex.includes(entry) || out.includes(pi)) break;
      out.push(pi);
      const o = ex[0] === entry ? ex[1] : ex[0];
      const r = Math.floor(slot / def.cols), c = slot % def.cols;
      const [nr, nc] = o === 'N' ? [r - 1, c] : o === 'S' ? [r + 1, c] : o === 'E' ? [r, c + 1] : [r, c - 1];
      if (nr < 0 || nc < 0 || nr >= def.rows || nc >= def.cols) break;
      slot = nr * def.cols + nc; entry = OPP[o];
    }
    return out;
  };
  const pick = (s: number) => {
    if (done) return;
    if (selected === null) { selected = s; ctx.sfx('pick'); }
    else if (selected === s) { selected = null; }
    else { [st.slots[selected], st.slots[s]] = [st.slots[s], st.slots[selected]]; selected = null; ctx.sfx('swap'); }
    after();
  };
  const after = () => {
    draw();
    const seen = tracePanels(def, st);
    if (panelsSolved(def, st)) { done = true; grid.classList.add('solved'); ctx.sfx('solve'); ctx.solved(); }
    else if (seen) ctx.status('The path connects, but the frames are out of order. Follow the times.');
    else ctx.status(`${partial().length} of ${n} frames connected from the start marker.`);
  };

  ctx.root.append(h('div', { class: 'board-frame' }, h('p', { class: 'board-caption', text: 'Start at the gold marker. Swap frames, zoom in or out, and join the path.' }), grid));
  after();
  return {};
};
