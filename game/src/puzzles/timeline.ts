// Timeline ordering: no timestamps on the cards. Drag a card by its handle, use the arrows, or tap
// two cards to swap them, then check. A wrong check says how many cards are already in place.
// Only the handle captures touch, so a swipe anywhere else on a card still scrolls the page.

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
  let suppressClick = false;
  const byId = new Map(def.cards.map((c) => [c.id, c]));

  const list = h('ol', { class: 'tl-list' });
  const check = h('button', { class: 'btn primary', text: 'Check the order' });

  const move = (a: number, b: number) => {
    if (done || b < 0 || b >= order.length) return;
    const [x] = order.splice(a, 1);
    order.splice(b, 0, x);
    sel = null; ctx.sfx('paper'); draw();
  };
  const tap = (i: number) => {
    if (done || suppressClick) return;
    if (sel === null) { sel = i; ctx.sfx('pick'); }
    else if (sel === i) sel = null;
    else { [order[sel], order[i]] = [order[i], order[sel]]; sel = null; ctx.sfx('swap'); }
    draw();
  };

  const draw = () => {
    list.innerHTML = '';
    order.forEach((id, i) => {
      const c = byId.get(id)!;
      const grip = h('span', { class: 'tl-grip', role: 'img', 'aria-label': `Drag handle for ${c.title}`, text: '⠿' });
      const li = h('li', { class: `tl-card${sel === i ? ' sel' : ''}`, 'data-i': i, tabindex: 0 },
        h('span', { class: 'tl-pos', text: i + 1 }),
        grip,
        h('div', { class: 'tl-body' }, h('strong', { text: c.title }), h('span', { text: c.detail })),
        h('div', { class: 'tl-arrows' },
          h('button', { class: 'tl-up', 'aria-label': `Move ${c.title} earlier`, text: '▲', disabled: i === 0 || done ? true : undefined, onclick: (e: Event) => { e.stopPropagation(); move(i, i - 1); } }),
          h('button', { class: 'tl-down', 'aria-label': `Move ${c.title} later`, text: '▼', disabled: i === order.length - 1 || done ? true : undefined, onclick: (e: Event) => { e.stopPropagation(); move(i, i + 1); } })));
      li.addEventListener('click', () => tap(i));

      let startY: number | null = null;
      grip.addEventListener('pointerdown', (e) => {
        if (done) return;
        e.preventDefault();
        grip.setPointerCapture(e.pointerId);
        startY = e.clientY;
        li.classList.add('dragging');
      });
      grip.addEventListener('pointermove', (e) => {
        if (startY === null) return;
        li.style.transform = `translateY(${e.clientY - startY}px)`;
      });
      const finish = (e: PointerEvent, cancelled: boolean) => {
        if (startY === null) return;
        const dy = e.clientY - startY;
        startY = null;
        li.classList.remove('dragging');
        li.style.transform = '';
        suppressClick = true;
        setTimeout(() => { suppressClick = false; }, 60);
        if (cancelled) return;
        const step = li.getBoundingClientRect().height + 8;
        const to = Math.max(0, Math.min(order.length - 1, i + Math.round(dy / step)));
        if (to !== i) move(i, to);
      };
      grip.addEventListener('pointerup', (e) => finish(e, false));
      grip.addEventListener('pointercancel', (e) => finish(e, true));
      list.append(li);
    });
  };

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
  ctx.status('Earliest at the top. Drag the handle ⠿, or use the arrows. The evidence board has the facts.');
  return {};
};
