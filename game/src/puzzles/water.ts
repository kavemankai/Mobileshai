// Water sort: pour the top layer into a tank that is empty or has the same colour on top.

import { inkFor } from '../core/color';
import { h } from '../core/dom';
import type { PuzzleMount, WaterDef } from '../core/types';

export function canPour(tubes: string[], cap: number, a: number, b: number): boolean {
  if (a === b || !tubes[a].length || tubes[b].length >= cap) return false;
  return !tubes[b].length || tubes[b].at(-1) === tubes[a].at(-1);
}

export function pour(tubes: string[], cap: number, a: number, b: number): string[] {
  const t = tubes.slice();
  const c = t[a].at(-1)!;
  let run = 0;
  for (let i = t[a].length - 1; i >= 0 && t[a][i] === c; i--) run++;
  const n = Math.min(run, cap - t[b].length);
  t[a] = t[a].slice(0, t[a].length - n);
  t[b] = t[b] + c.repeat(n);
  return t;
}

export const waterSolved = (tubes: string[], cap: number) => tubes.every((t) => !t.length || (t.length === cap && [...t].every((x) => x === t[0])));

export const mountWater: PuzzleMount<WaterDef> = (def, ctx) => {
  let tubes = def.tubes.slice();
  const history: string[][] = [];
  let sel: number | null = null;
  let done = false;
  const row = h('div', { class: 'ws-row' });
  const undo = h('button', { class: 'btn', text: 'Undo pour' });

  const draw = () => {
    row.innerHTML = '';
    tubes.forEach((t, i) => {
      const tube = h('button', { class: `ws-tube${sel === i ? ' sel' : ''}`, 'aria-label': `Tank ${i + 1}: ${[...t].map((c) => def.colors[c].label).join(', ') || 'empty'}` });
      for (let k = def.capacity - 1; k >= 0; k--) {
        const c = t[k];
        tube.append(h('span', { class: `ws-layer${c ? '' : ' empty'}`, style: c ? { background: def.colors[c].color, color: inkFor(def.colors[c].color) } : undefined, text: c ? def.colors[c].label[0] : '' }));
      }
      tube.addEventListener('click', () => tap(i));
      row.append(tube);
    });
    undo.disabled = !history.length || done;
  };

  const tap = (i: number) => {
    if (done) return;
    if (sel === null) { if (tubes[i].length) { sel = i; ctx.sfx('pick'); } draw(); return; }
    if (sel === i) { sel = null; draw(); return; }
    if (canPour(tubes, def.capacity, sel, i)) {
      history.push(tubes);
      tubes = pour(tubes, def.capacity, sel, i);
      ctx.sfx('pour');
      sel = null; draw();
      if (waterSolved(tubes, def.capacity)) { done = true; row.classList.add('solved'); ctx.sfx('power'); ctx.solved(); }
    } else { ctx.sfx('invalid'); ctx.status('You can only pour onto the same liquid or into an empty tank.'); sel = null; draw(); }
  };

  undo.addEventListener('click', () => { if (history.length && !done) { tubes = history.pop()!; sel = null; ctx.sfx('tap'); draw(); } });
  const legend = h('div', { class: 'gs-legend' }, ...Object.values(def.colors).map((c) => h('span', { style: { background: c.color, color: inkFor(c.color) }, text: c.label })));
  ctx.root.append(h('div', { class: 'board-frame' }, h('p', { class: 'board-caption', text: 'Tap a tank, then the tank to pour into. Each tank must end up holding one liquid.' }), row, legend, h('div', { class: 'board-actions' }, undo)));
  draw();
  ctx.status('The pump only runs on separated tanks.');
  return {};
};
