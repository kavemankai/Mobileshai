// Puzzle box: a mechanism opened in stages. Each stage reveals a note that helps with a later one.

import { h, wait } from '../core/dom';
import type { BoxDef, BoxStage, PuzzleCtx, PuzzleMount } from '../core/types';
import { evidencePeek } from './peek';
import { tiltWidget } from './tilt';

export function leverToggle(state: number[], i: number): number[] {
  const n = Math.round(Math.sqrt(state.length));
  const s = state.slice();
  const r = Math.floor(i / n), c = i % n;
  for (const [dr, dc] of [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]]) {
    const rr = r + dr, cc = c + dc;
    if (rr >= 0 && cc >= 0 && rr < n && cc < n) s[rr * n + cc] ^= 1;
  }
  return s;
}

/** Minimum presses to light every lever, or -1. Brute force; fine up to 4x4. */
export function leverSolve(start: number[]): number {
  const N = start.length;
  let best = -1;
  for (let mask = 0; mask < 1 << N; mask++) {
    let s = start;
    let k = 0;
    for (let i = 0; i < N; i++) if (mask & (1 << i)) { s = leverToggle(s, i); k++; }
    if (s.every(Boolean) && (best < 0 || k < best)) best = k;
  }
  return best;
}

type StageCtx = Pick<PuzzleCtx, 'sfx' | 'haptic' | 'status' | 'reducedMotion' | 'clues'>;
type StageView = (stage: BoxStage, ctx: StageCtx, done: () => void) => HTMLElement;

const screws: StageView = (st, ctx, done) => {
  if (st.type !== 'screws') throw new Error();
  let left = st.count;
  const plate = h('div', { class: 'bx-plate' }, h('span', { class: 'bx-plate-label', text: st.plate }));
  for (let i = 0; i < st.count; i++) {
    const a = (i / st.count) * Math.PI * 2 + 0.6;
    const s = h('button', { class: 'bx-screw', 'aria-label': `Screw ${i + 1}`, style: { left: `${50 + Math.cos(a) * 38}%`, top: `${50 + Math.sin(a) * 34}%` } });
    s.addEventListener('click', () => {
      if (s.classList.contains('out')) return;
      s.classList.add('out'); ctx.sfx('ratchet'); ctx.haptic(10);
      if (--left === 0) { plate.classList.add('drop'); ctx.sfx('metal'); done(); }
      else ctx.status(`${left} screw${left === 1 ? '' : 's'} left.`);
    });
    plate.append(s);
  }
  ctx.status('Unscrew the plate.');
  return plate;
};

const sliders: StageView = (st, ctx, done) => {
  if (st.type !== 'sliders') throw new Error();
  const pos = st.targets.map((t) => (t + 2) % 5);
  const wrap = h('div', { class: 'bx-sliders' });
  const draw = () => {
    wrap.innerHTML = '';
    pos.forEach((p, i) => {
      const track = h('div', { class: 'bx-track', role: 'group', 'aria-label': `Slider ${i + 1}, position ${p}` });
      for (let k = 0; k < 5; k++) {
        const notch = h('button', { class: `bx-notch${k === p ? ' knob' : ''}`, text: String(k), 'aria-label': `Set slider ${i + 1} to ${k}` });
        notch.addEventListener('click', () => { pos[i] = k; ctx.sfx('click'); draw(); check(); });
        track.append(notch);
      }
      wrap.append(track);
    });
  };
  let fin = false;
  const check = () => { if (!fin && pos.every((p, i) => p === st.targets[i])) { fin = true; wrap.classList.add('ok'); done(); } };
  draw();
  ctx.status(st.clue);
  return h('div', null, h('p', { class: 'bx-clue', text: st.clue }), wrap);
};

const dials: StageView = (st, ctx, done) => {
  if (st.type !== 'dials') throw new Error();
  const val = [...st.code].map((d) => (Number(d) + 5) % 10);
  const wrap = h('div', { class: 'bx-dials' });
  let fin = false;
  const draw = () => {
    wrap.innerHTML = '';
    val.forEach((v, i) => {
      const turn = (d: number) => { if (fin) return; val[i] = (v + d + 10) % 10; ctx.sfx('click'); draw(); if (val.join('') === st.code) { fin = true; done(); } };
      wrap.append(h('div', { class: 'bx-dial' },
        h('button', { class: 'cx-btn', text: '▲', 'aria-label': `Dial ${i + 1} up`, onclick: () => turn(1) }),
        h('span', { class: 'bx-digit', text: String(v), 'aria-label': `Dial ${i + 1}: ${v}` }),
        h('button', { class: 'cx-btn', text: '▼', 'aria-label': `Dial ${i + 1} down`, onclick: () => turn(-1) })));
    });
  };
  draw();
  ctx.status(st.clue);
  return h('div', null, h('p', { class: 'bx-clue', text: st.clue }), wrap, st.evidence ? evidencePeek(ctx.clues) : null);
};

const levers: StageView = (st, ctx, done) => {
  if (st.type !== 'levers') throw new Error();
  let s = st.start.slice();
  const n = Math.round(Math.sqrt(s.length));
  const wrap = h('div', { class: 'bx-levers', style: { gridTemplateColumns: `repeat(${n}, 1fr)`, maxWidth: `${Math.max(240, n * 66)}px` } });
  let fin = false;
  const draw = () => {
    wrap.innerHTML = '';
    s.forEach((v, i) => {
      const b = h('button', { class: `bx-lever${v ? ' on' : ''}`, 'aria-label': `Lever ${i + 1}, ${v ? 'up' : 'down'}`, 'aria-pressed': v ? 'true' : 'false' });
      b.addEventListener('click', () => { if (fin) return; s = leverToggle(s, i); ctx.sfx('click'); draw(); if (s.every(Boolean)) { fin = true; done(); } });
      wrap.append(b);
    });
  };
  draw();
  ctx.status(st.clue);
  return h('div', null, h('p', { class: 'bx-clue', text: st.clue }), wrap);
};

const press: StageView = (st, ctx, done) => {
  if (st.type !== 'press') throw new Error();
  const wrap = h('div', { class: 'bx-rivets' });
  let fin = false;
  for (let i = 0; i < st.count; i++) {
    const b = h('button', { class: `bx-rivet${i === st.target ? ' odd' : ''}`, 'aria-label': `Panel ${i + 1}` });
    b.addEventListener('click', () => {
      if (fin) return;
      if (i === st.target) { fin = true; b.classList.add('pressed'); done(); }
      else { ctx.sfx('tap'); ctx.status('Solid. Nothing moves.'); }
    });
    wrap.append(b);
  }
  ctx.status(st.clue);
  return h('div', null, h('p', { class: 'bx-clue', text: st.clue }), wrap);
};

const patch: StageView = (st, ctx, done) => {
  if (st.type !== 'patch') throw new Error();
  const linked = new Set<number>();
  let pickL: number | null = null;
  const wrap = h('div', { class: 'bx-patch' });
  const draw = () => {
    wrap.innerHTML = '';
    const L = h('div', { class: 'bx-jacks' }), R = h('div', { class: 'bx-jacks' });
    st.left.forEach((name, i) => {
      const b = h('button', { class: `bx-jack${linked.has(i) ? ' linked' : ''}${pickL === i ? ' sel' : ''}`, text: name });
      b.addEventListener('click', () => { if (linked.has(i)) return; pickL = i; ctx.sfx('pick'); draw(); });
      L.append(b);
    });
    st.right.forEach((name, j) => {
      const used = [...linked].some((i) => st.pairs[i] === j);
      const b = h('button', { class: `bx-jack${used ? ' linked' : ''}`, text: name });
      b.addEventListener('click', () => {
        if (pickL === null || used) { ctx.status('Pick a cable on the left first.'); return; }
        if (st.pairs[pickL] === j) { linked.add(pickL); ctx.sfx('latch'); ctx.haptic(8); }
        else { ctx.sfx('static'); ctx.status('Sparks. Wrong socket.'); }
        pickL = null; draw();
        if (linked.size === st.left.length) done();
      });
      R.append(b);
    });
    wrap.append(L, h('div', { class: 'bx-cables', text: '⟶' }), R);
  };
  draw();
  ctx.status(st.clue);
  return h('div', null, h('p', { class: 'bx-clue', text: st.clue }), wrap);
};

const tiltStage: StageView = (st, ctx, done) => {
  if (st.type !== 'tilt') throw new Error();
  return h('div', null, h('p', { class: 'bx-clue', text: st.clue }), tiltWidget(st.rows, ctx, done));
};

const VIEWS: Record<BoxStage['type'], StageView> = { screws, sliders, dials, levers, press, patch, tilt: tiltStage };

export const mountBox: PuzzleMount<BoxDef> = (def, ctx) => {
  let idx = 0;
  const head = h('div', { class: 'bx-head' });
  const stageBox = h('div', { class: 'bx-stage' });
  const notes = h('ul', { class: 'bx-notes' });
  const frame = h('div', { class: 'board-frame bx-frame' }, head, stageBox, h('p', { class: 'bx-notes-title', text: 'Found on the mechanism' }), notes);

  const show = () => {
    const st = def.stages[idx];
    head.innerHTML = '';
    head.append(h('strong', { text: def.name }), h('span', { text: `Stage ${idx + 1} of ${def.stages.length}` }),
      h('div', { class: 'bx-pips' }, ...def.stages.map((_, i) => h('span', { class: i < idx ? 'done' : i === idx ? 'now' : '' }))));
    stageBox.innerHTML = '';
    stageBox.append(VIEWS[st.type](st, ctx, async () => {
      ctx.sfx('latch');
      notes.append(h('li', { text: st.note }));
      stageBox.classList.add('opened');
      await wait(ctx.reducedMotion ? 150 : 700);
      stageBox.classList.remove('opened');
      idx++;
      if (idx >= def.stages.length) { frame.classList.add('solved'); ctx.sfx('solve'); ctx.solved(); }
      else show();
    }));
  };
  ctx.root.append(frame);
  show();
  return {};
};
