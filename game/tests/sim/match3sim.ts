// Simulated players for match-3 balance. Uses the game's own rule functions, so a change to the
// rules or to a level's static mask shows up in the numbers.

import { rng } from '../../src/core/rng';
import type { Match3Def } from '../../src/core/types';
import { adjacent, findMatches, hasMove, newBoard, staticLeft, step, swapTiles, type M3, type Splash } from '../../src/puzzles/match3';

export type Policy = 'first' | 'random' | 'smart';

export function legalMoves(g: M3): [number, number][] {
  const out: [number, number][] = [];
  for (let a = 0; a < g.n * g.n; a++) for (const b of [a + 1, a + g.n]) {
    if (b >= g.n * g.n || !adjacent(g.n, a, b)) continue;
    swapTiles(g, a, b);
    if (findMatches(g).cells.size) out.push([a, b]);
    swapTiles(g, a, b);
  }
  return out;
}

function clone(g: M3, seed: number): M3 {
  return { n: g.n, k: g.k, tiles: g.tiles.map((t) => (t ? { ...t } : null)), stat: g.stat.slice(), rand: rng(seed) };
}

/** Plays one swap and its cascade, then reshuffles if the board is stuck. */
export function applyMove(g: M3, [a, b]: [number, number], splash: Splash) {
  swapTiles(g, a, b);
  let chain = 0;
  while (step(g, chain === 0 ? [a, b] : [], splash)) chain++;
  if (!hasMove(g)) {
    do { g.tiles = g.tiles.map(() => ({ c: Math.floor(g.rand() * g.k) })); } while (findMatches(g).cells.size || !hasMove(g));
  }
}

export function swapsToClear(def: Match3Def, seed: number, policy: Policy, splash: Splash = def.splash ?? 'ends', cap = 600): number {
  const g = newBoard(def, seed);
  const pick = rng(seed * 31 + 7);
  let swaps = 0;
  while (staticLeft(g) && swaps < cap) {
    const moves = legalMoves(g);
    if (!moves.length) break;
    let mv = moves[0];
    if (policy === 'random') mv = moves[Math.floor(pick() * moves.length)];
    if (policy === 'smart') {
      let best = -1;
      for (const m of moves) {
        const c = clone(g, 99);
        const before = staticLeft(c);
        applyMove(c, m, splash);
        const cleared = before - staticLeft(c);
        if (cleared > best) { best = cleared; mv = m; }
      }
    }
    applyMove(g, mv, splash);
    swaps++;
  }
  return staticLeft(g) ? cap : swaps;
}

export const median = (xs: number[]) => { const s = xs.slice().sort((a, b) => a - b); return s[Math.floor(s.length / 2)]; };
export const percentile = (xs: number[], p: number) => { const s = xs.slice().sort((a, b) => a - b); return s[Math.min(s.length - 1, Math.floor(s.length * p))]; };
