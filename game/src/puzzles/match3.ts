// Match-3 reveal: matches wipe the static off the cells beneath them. Clear all static to
// reveal the picture. No move limit. Four in a row makes a line clearer.

import { MATCH_TILES } from '../assets/manifest';
import { h, wait } from '../core/dom';
import { rng } from '../core/rng';
import type { Match3Def, PuzzleMount } from '../core/types';

export interface Tile { c: number; sp?: 'row' | 'col' }
export interface M3 { n: number; k: number; tiles: (Tile | null)[]; stat: boolean[]; rand: () => number }

export function newBoard(def: Match3Def, seed: number): M3 {
  const n = def.size, k = def.colors, rand = rng(seed);
  const stat = def.mask.join('').split('').map((ch) => ch === '#');
  if (stat.length !== n * n) throw new Error('match3 mask size mismatch');
  const g: M3 = { n, k, tiles: [], stat, rand };
  do {
    g.tiles = [];
    for (let i = 0; i < n * n; i++) {
      let c: number;
      do { c = Math.floor(rand() * k); } while (
        (i % n >= 2 && g.tiles[i - 1]?.c === c && g.tiles[i - 2]?.c === c) ||
        (i >= 2 * n && g.tiles[i - n]?.c === c && g.tiles[i - 2 * n]?.c === c)
      );
      g.tiles.push({ c });
    }
  } while (!hasMove(g));
  return g;
}

export interface MatchResult { cells: Set<number>; specials: { at: number; sp: 'row' | 'col'; c: number }[] }

export function findMatches(g: M3, prefer: number[] = []): MatchResult {
  const { n, tiles } = g;
  const cells = new Set<number>();
  const specials: MatchResult['specials'] = [];
  const scan = (horizontal: boolean) => {
    for (let a = 0; a < n; a++) {
      let run: number[] = [];
      for (let b = 0; b <= n; b++) {
        const i = horizontal ? a * n + b : b * n + a;
        const t = b < n ? tiles[i] : null;
        if (t && run.length && tiles[run[0]]?.c === t.c) run.push(i);
        else {
          if (run.length >= 3) {
            run.forEach((x) => cells.add(x));
            if (run.length >= 4) {
              const at = run.find((x) => prefer.includes(x)) ?? run[Math.floor(run.length / 2)];
              specials.push({ at, sp: horizontal ? 'row' : 'col', c: tiles[run[0]]!.c });
            }
          }
          run = t ? [i] : [];
        }
      }
    }
  };
  scan(true); scan(false);
  // Specials caught in a match fire their line.
  const queue = [...cells];
  while (queue.length) {
    const i = queue.pop()!;
    const t = tiles[i];
    if (!t?.sp) continue;
    const r = Math.floor(i / n), c = i % n;
    for (let x = 0; x < n; x++) {
      const j = t.sp === 'row' ? r * n + x : x * n + c;
      if (!cells.has(j)) { cells.add(j); queue.push(j); }
    }
  }
  return { cells, specials };
}

export function swapTiles(g: M3, a: number, b: number) { [g.tiles[a], g.tiles[b]] = [g.tiles[b], g.tiles[a]]; }

export const adjacent = (n: number, a: number, b: number) => (Math.abs(a - b) === 1 && Math.floor(a / n) === Math.floor(b / n)) || Math.abs(a - b) === n;

export function hasMove(g: M3): number[] | null {
  const { n } = g;
  for (let i = 0; i < n * n; i++) {
    for (const j of [i + 1, i + n]) {
      if (j >= n * n || !adjacent(n, i, j)) continue;
      swapTiles(g, i, j);
      const ok = findMatches(g).cells.size > 0;
      swapTiles(g, i, j);
      if (ok) return [i, j];
    }
  }
  return null;
}

/** Clears matched cells, wipes static under them, drops tiles, refills. Returns true if anything cleared. */
export function step(g: M3, prefer: number[] = []): boolean {
  const { cells, specials } = findMatches(g, prefer);
  if (!cells.size) return false;
  cells.forEach((i) => { g.tiles[i] = null; g.stat[i] = false; });
  specials.forEach((s) => { g.tiles[s.at] = { c: s.c, sp: s.sp }; });
  gravity(g);
  return true;
}

export function gravity(g: M3) {
  const { n } = g;
  for (let c = 0; c < n; c++) {
    const col = [];
    for (let r = n - 1; r >= 0; r--) if (g.tiles[r * n + c]) col.push(g.tiles[r * n + c]);
    for (let r = n - 1, k = 0; r >= 0; r--, k++) g.tiles[r * n + c] = col[k] ?? { c: Math.floor(g.rand() * g.k) };
  }
}

export const staticLeft = (g: M3) => g.stat.filter(Boolean).length;

const COLORS = ['#e8b877', '#7fb7ad', '#c8665a', '#9a8fc9', '#d9d2c2', '#6f9ed6'];
const SHAPES = ['●', '◆', '■', '▲', '✚', '⬣'];

export const mountMatch3: PuzzleMount<Match3Def> = (def, ctx) => {
  const g = newBoard(def, ctx.seed);
  const total = staticLeft(g);
  let sel: number | null = null;
  let busy = false, done = false;

  const reveal = h('div', { class: 'm3-reveal' }, h('strong', { text: def.reveal.title }), ...def.reveal.lines.map((l) => h('span', { text: l })));
  const grid = h('div', { class: 'm3-grid', style: { gridTemplateColumns: `repeat(${g.n}, 1fr)` } });
  const meter = h('div', { class: 'm3-meter' }, h('span'));

  const draw = (fresh?: Set<number>) => {
    grid.innerHTML = '';
    g.tiles.forEach((t, i) => {
      const cell = h('div', { class: `m3-cell${g.stat[i] ? ' static' : ''}` });
      if (t) {
        const tile = h('button', {
          class: `m3-tile${sel === i ? ' sel' : ''}${t.sp ? ' sp-' + t.sp : ''}${fresh?.has(i) ? ' drop' : ''}`,
          style: { color: COLORS[t.c] }, text: MATCH_TILES[t.c] ? undefined : SHAPES[t.c], 'data-i': i,
          'aria-label': `Tile ${SHAPES[t.c]}${t.sp ? ' line clearer' : ''}, row ${Math.floor(i / g.n) + 1} column ${(i % g.n) + 1}`,
        });
        if (MATCH_TILES[t.c]) { tile.classList.add('sprite'); tile.append(h('img', { src: MATCH_TILES[t.c], alt: '', draggable: 'false' })); }
        cell.append(tile);
      }
      grid.append(cell);
    });
    const left = staticLeft(g);
    (meter.firstChild as HTMLElement).style.width = `${100 - (left / total) * 100}%`;
    ctx.status(left ? `Static remaining: ${left} cells` : 'Signal restored.');
  };

  const tryswap = async (a: number, b: number) => {
    if (busy || done || !adjacent(g.n, a, b)) return;
    busy = true; sel = null;
    swapTiles(g, a, b);
    if (!findMatches(g).cells.size) {
      draw(); ctx.sfx('invalid');
      await wait(ctx.reducedMotion ? 60 : 200);
      swapTiles(g, a, b); draw(); busy = false; return;
    }
    ctx.sfx('swap');
    let chain = 0;
    while (step(g, chain === 0 ? [a, b] : [])) {
      chain++;
      ctx.sfx(chain > 1 ? 'combo' : 'clear'); ctx.haptic(8);
      draw(new Set(g.tiles.map((_, i) => i).filter(() => true)));
      await wait(ctx.reducedMotion ? 60 : 220);
    }
    if (!hasMove(g)) {
      // Reshuffle colours without touching the static.
      do { g.tiles = g.tiles.map(() => ({ c: Math.floor(g.rand() * g.k) })); } while (findMatches(g).cells.size || !hasMove(g));
      ctx.status('No moves left. Reshuffled.');
    }
    draw();
    busy = false;
    if (!staticLeft(g)) { done = true; grid.classList.add('solved'); ctx.sfx('solve'); ctx.solved(); }
  };

  let downAt: { i: number; x: number; y: number } | null = null;
  grid.addEventListener('pointerdown', (e) => {
    const t = (e.target as HTMLElement).closest('[data-i]') as HTMLElement | null;
    if (!t) return;
    downAt = { i: Number(t.dataset.i), x: e.clientX, y: e.clientY };
  });
  grid.addEventListener('pointerup', (e) => {
    if (!downAt) return;
    const { i, x, y } = downAt; downAt = null;
    const dx = e.clientX - x, dy = e.clientY - y;
    if (Math.hypot(dx, dy) > 18) {
      const j = Math.abs(dx) > Math.abs(dy) ? i + Math.sign(dx) : i + Math.sign(dy) * g.n;
      if (j >= 0 && j < g.n * g.n) void tryswap(i, j);
      return;
    }
    if (sel === null) { sel = i; ctx.sfx('pick'); draw(); }
    else if (sel === i) { sel = null; draw(); }
    else if (adjacent(g.n, sel, i)) void tryswap(sel, i);
    else { sel = i; draw(); }
  });

  ctx.root.append(h('div', { class: 'board-frame m3-frame' }, meter, h('div', { class: 'm3-stack' }, reveal, grid)));
  draw();
  return {};
};
