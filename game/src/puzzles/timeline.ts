// Timeline ordering: no timestamps on the cards. Drag (or tap two to swap) into order, then
// check. A wrong check tells you how many cards are already in place.

import { h } from '../core/dom';
import { rng, shuffle } from '../core/rng';
import type { PuzzleMount, TimelineDef } from '../core/types';

export const inPlace = (def: TimelineDef, order: string[]) => order.filter((id, i) => def.order[i] === id).length;

export const mountTimeline: PuzzleMount<TimelineDef> = (def, ctx) => {
  const rand = rng(ctx.seed);
  let order: string[];
  do { order = shuffle(def.order, rand); } while (inPlace(def, order) > 1);
  let sel: number | null = null;
  let done = false;
  const byId = new Map(def.cards.map((c) => [c.id, c]));

  const list = h('ol', { class: 'tl-list' });
  const check = h('button', { class: 'btn primary', text: 'Check the order' });

  const draw = () => {
    list.innerHTML = '';
    order.forEach((id, i) => {
      const c = byId.get(id)!;
      const li = h('li', { class: `tl-card${sel === i ? ' sel' : ''}`, 'data-i': i, tabindex: 0 },
        h('span', { class: 'tl-pos', text: i + 1 }),
        h('div', { class: 'tl-body' }, h('strong', { text: c.title }), h('span', { text: c.detail })),
        h('div', { class: 'tl-arrows' },
          h('button', { class: 'tl-up', 'aria-label': `Move ${c.title} earlier`, text: '▲', disabled: i === 0 || done ? true : undefined, onclick: (e: Event) => { e.stopPropagation(); move(i, i - 1); } }),
          h('button', { class: 'tl-down', 'aria-label': `Move ${c.title} later`, text: '▼', disabled: i === order.length - 1 || done ? true : undefined, onclick: (e: Event) => { e.stopPropagation(); move(i, i + 1); } })));
      li.addEventListener('click', () => tap(i));
      list.append(li);
    });
  };
  const move = (a: number, b: number) => {
    if (done || b < 0 || b >= order.length) return;
    const [x] = order.splice(a, 1);
    order.splice(b, 0, x);
    sel = null; ctx.sfx('paper'); draw();
  };
  const tap = (i: number) => {
    if (done) return;
    if (sel === null) { sel = i; ctx.sfx('pick'); }
    else if (sel === i) sel = null;
    else { [order[sel], order[i]] = [order[i], order[sel]]; sel = null; ctx.sfx('swap'); }
    draw();
  };

  // Drag to reorder: long-ish press then move vertically.
  let drag: { from: number; y: number; el: HTMLElement } | null = null;
  list.addEventListener('pointerdown', (e) => {
    if ((e.target as HTMLElement).closest('button')) return;
    const li = (e.target as HTMLElement).closest('.tl-card') as HTMLElement | null;
    if (!li || done) return;
    drag = { from: Number(li.dataset.i), y: e.clientY, el: li };
  });
  list.addEventListener('pointermove', (e) => {
    if (!drag) return;
    const dy = e.clientY - drag.y;
    if (Math.abs(dy) < 8) return;
    drag.el.classList.add('dragging');
    drag.el.style.transform = `translateY(${dy}px)`;
  });
  const endDrag = (e: PointerEvent) => {
    if (!drag) return;
    const d = drag; drag = null;
    if (!d.el.classList.contains('dragging')) return;
    const h0 = d.el.getBoundingClientRect().height + 8;
    const to = Math.max(0, Math.min(order.length - 1, d.from + Math.round((e.clientY - d.y) / h0)));
    sel = null;
    if (to !== d.from) move(d.from, to); else draw();
  };
  list.addEventListener('pointerup', endDrag);
  list.addEventListener('pointercancel', () => { drag = null; draw(); });

  check.addEventListener('click', () => {
    if (done) return;
    const n = inPlace(def, order);
    if (n === order.length) {
      done = true; list.classList.add('solved'); check.disabled = true; draw(); ctx.sfx('solve'); ctx.solved();
    } else {
      ctx.sfx('invalid');
      ctx.status(`${n} of ${order.length} in the right place.`);
    }
  });

  ctx.root.append(h('div', { class: 'board-frame paper' }, h('p', { class: 'board-caption', text: def.prompt }), list, h('div', { class: 'board-actions' }, check)));
  draw();
  ctx.status('Earliest at the top. Use the evidence board if you need the facts.');
  return {};
};
