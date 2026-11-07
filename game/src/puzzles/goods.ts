// Goods sort: move cards between racks. Three matching cards on a rack lock and clear.
// The case is solved when only the leftover card remains.

import { h, wait } from '../core/dom';
import type { GoodsDef, PuzzleMount } from '../core/types';

export type Racks = string[][];

export function clearFull(racks: Racks, capacity: number): boolean {
  let any = false;
  for (const r of racks) {
    if (r.length === capacity && r.every((x) => x && x === r[0])) { r.length = 0; any = true; }
  }
  return any;
}

export const goodsSolved = (def: GoodsDef, racks: Racks) => {
  const left = racks.flat().filter(Boolean);
  return left.length === 1 && left[0] === def.leftover;
};

export function initRacks(def: GoodsDef): Racks {
  return def.racks.map((r) => r.filter(Boolean));
}

export const mountGoods: PuzzleMount<GoodsDef> = (def, ctx) => {
  const racks = initRacks(def);
  let sel: [number, number] | null = null;
  let busy = false, done = false;
  const wrap = h('div', { class: 'gs-racks' });

  const draw = () => {
    wrap.innerHTML = '';
    racks.forEach((r, ri) => {
      const rack = h('button', { class: 'gs-rack', 'aria-label': `Rack ${ri + 1}, ${r.length} of ${def.capacity} slots used. Tap to move the selected card here.` });
      for (let s = 0; s < def.capacity; s++) {
        const id = r[s];
        if (id) {
          const t = def.types[id];
          const card = h('span', {
            class: `gs-card${sel && sel[0] === ri && sel[1] === s ? ' sel' : ''}`, role: 'button', tabindex: 0,
            style: { background: t.color }, text: t.label, 'aria-label': `${t.label} card`,
          });
          card.addEventListener('click', (e) => { e.stopPropagation(); pickCard(ri, s); });
          rack.append(card);
        } else rack.append(h('span', { class: 'gs-slot' }));
      }
      rack.addEventListener('click', () => dropOn(ri));
      wrap.append(rack);
    });
    const left = racks.flat().length;
    ctx.status(`${left} card${left === 1 ? '' : 's'} on the racks.`);
  };

  const pickCard = (ri: number, s: number) => {
    if (busy || done) return;
    if (sel && sel[0] === ri && sel[1] === s) { sel = null; draw(); return; }
    if (sel && sel[0] !== ri) { dropOn(ri); return; }
    sel = [ri, s]; ctx.sfx('pick'); draw();
  };

  const dropOn = async (ri: number) => {
    if (busy || done || !sel) return;
    const [from, s] = sel;
    if (from === ri) { sel = null; draw(); return; }
    if (racks[ri].length >= def.capacity) { ctx.sfx('invalid'); ctx.status('That rack is full.'); return; }
    const [card] = racks[from].splice(s, 1);
    racks[ri].push(card);
    sel = null; ctx.sfx('place'); draw();
    if (racks.some((r) => r.length === def.capacity && r.every((x) => x === r[0]))) {
      busy = true;
      await wait(ctx.reducedMotion ? 50 : 260);
      clearFull(racks, def.capacity);
      ctx.sfx('clear'); ctx.haptic(10);
      busy = false;
      draw();
    }
    if (goodsSolved(def, racks)) { done = true; wrap.classList.add('solved'); ctx.sfx('solve'); ctx.solved(); }
  };

  const legend = h('div', { class: 'gs-legend' }, ...Object.values(def.types).map((t) => h('span', { style: { background: t.color }, text: t.label })));
  ctx.root.append(h('div', { class: 'board-frame' }, h('p', { class: 'board-caption', text: 'Tap a card, then tap a rack with space. Three of a kind lock away.' }), wrap, legend));
  draw();
  return {};
};
