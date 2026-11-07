// Cryptex: turn the letter rings to spell the password.

import { h } from '../core/dom';
import { rng } from '../core/rng';
import { evidencePeek } from './peek';
import type { CryptexDef, PuzzleMount } from '../core/types';

export const cryptexWord = (def: CryptexDef, pos: number[]) => pos.map((p, i) => def.rings[i][p]).join('');

export const mountCryptex: PuzzleMount<CryptexDef> = (def, ctx) => {
  const rand = rng(ctx.seed);
  const pos = def.rings.map((r, i) => {
    let p: number;
    do { p = Math.floor(rand() * r.length); } while (r[p] === def.word[i]);
    return p;
  });
  let done = false;

  const body = h('div', { class: 'cx-body' });
  const rings: HTMLElement[] = [];
  def.rings.forEach((letters, i) => {
    const win = h('div', { class: 'cx-window' });
    const up = h('button', { class: 'cx-btn', text: '▲', 'aria-label': `Ring ${i + 1} up` });
    const down = h('button', { class: 'cx-btn', text: '▼', 'aria-label': `Ring ${i + 1} down` });
    const turn = (d: number) => { if (done) return; pos[i] = (pos[i] + d + letters.length) % letters.length; ctx.sfx('click'); ctx.haptic(5); draw(); };
    up.addEventListener('click', () => turn(-1));
    down.addEventListener('click', () => turn(1));
    let y0: number | null = null;
    win.addEventListener('pointerdown', (e) => { y0 = e.clientY; });
    win.addEventListener('pointerup', (e) => { if (y0 !== null && Math.abs(e.clientY - y0) > 14) turn(e.clientY > y0 ? -1 : 1); y0 = null; });
    rings.push(win);
    body.append(h('div', { class: 'cx-ring' }, up, win, down));
  });

  const draw = () => {
    def.rings.forEach((letters, i) => {
      const L = letters.length, p = pos[i];
      rings[i].innerHTML = '';
      rings[i].append(
        h('span', { class: 'cx-ghost', text: letters[(p - 1 + L) % L] }),
        h('span', { class: 'cx-letter', text: letters[p], 'aria-label': `Ring ${i + 1}: ${letters[p]}` }),
        h('span', { class: 'cx-ghost', text: letters[(p + 1) % L] }),
      );
    });
    if (cryptexWord(def, pos) === def.word) {
      done = true; body.classList.add('solved'); ctx.sfx('latch'); ctx.solved();
    }
  };

  const peek = evidencePeek(ctx.clues);

  ctx.root.append(h('div', { class: 'board-frame cx-frame' }, h('p', { class: 'board-caption', text: def.clue }), body, peek));
  draw();
  ctx.status('Swipe a ring or use the arrows. The cylinder opens when the word is right.');
  return {};
};
