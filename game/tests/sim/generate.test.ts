// Design generators. Not part of the normal suite: run with GEN=1 to search for puzzle data.
//   GEN=1 npx vitest run tests/sim/generate.test.ts
// Each generator prints lines starting with "G|" that can be pasted into src/story/levels.ts.
// Everything it finds is checked with the game's own rule functions.

import { describe, it } from 'vitest';
import { rng, shuffle } from '../../src/core/rng';
import type { Edge, LogicDef, LogicRule, PanelsDef } from '../../src/core/types';
import { leverSolve, leverToggle } from '../../src/puzzles/box';
import { logicSolutions } from '../../src/puzzles/logic';
import { tracePanels } from '../../src/puzzles/panels';
import { find, tiltPath, tiltSolve } from '../../src/puzzles/tilt';
import { canPour, pour, waterSolved } from '../../src/puzzles/water';
import { countZipSolutions, zipModel } from '../../src/puzzles/zip';

const GEN = !!process.env.GEN;
const d = GEN ? describe : describe.skip;
const out = (tag: string, v: unknown) => console.log(`G|${tag}|${JSON.stringify(v)}`);

// ---------- logic grids where every clue is needed ----------
type Ref = [number, number];
function logicRules(solution: [number, number][]): LogicRule[] {
  const rules: LogicRule[] = [];
  const n = solution.length;
  const link = (c1: number, i: number, c2: number, j: number) => {
    // Does item i of category c1 belong with item j of category c2 in the solution?
    const rowOf = (c: number, k: number) => (c === 0 ? k : solution.findIndex((s) => s[c - 1] === k));
    return rowOf(c1, i) === rowOf(c2, j);
  };
  for (const [c1, c2] of [[0, 1], [0, 2], [1, 2]]) for (let i = 0; i < n; i++) for (let j = 0; j < n; j++) {
    rules.push({ t: link(c1, i, c2, j) ? 'same' : 'diff', a: [c1, i] as Ref, b: [c2, j] as Ref });
  }
  return rules;
}
const fake = (n: number, rules: LogicRule[], solution: [number, number][]): LogicDef => ({
  kind: 'logic', solution, clues: rules.map((r) => ({ text: '', rule: r })),
  categories: [0, 1, 2].map((c) => ({ name: `c${c}`, items: Array.from({ length: n }, (_, k) => `${c}.${k}`) })),
});

function minimalSets(solution: [number, number][], k: number, accept: (rules: LogicRule[]) => boolean, want: number, seed: number) {
  const all = shuffle(logicRules(solution), rng(seed));
  const found: LogicRule[][] = [];
  const pick: LogicRule[] = [];
  const rec = (start: number) => {
    if (found.length >= want) return;
    if (pick.length === k) {
      if (logicSolutions(fake(solution.length, pick, solution)).length !== 1) return;
      // Minimal: dropping any one clue must leave more than one solution.
      for (let drop = 0; drop < k; drop++) {
        const rest = pick.filter((_, i) => i !== drop);
        if (logicSolutions(fake(solution.length, rest, solution)).length === 1) return;
      }
      if (accept(pick)) found.push(pick.slice());
      return;
    }
    for (let i = start; i < all.length && found.length < want; i++) { pick.push(all[i]); rec(i + 1); pick.pop(); }
  };
  rec(0);
  return found;
}

d('logic', () => {
  const sol: [number, number][] = [[0, 0], [1, 1], [2, 2]];
  const pairsUsed = (rs: LogicRule[]) => new Set(rs.map((r) => `${r.a[0]}${r.b[0]}`)).size;
  const sames = (rs: LogicRule[]) => rs.filter((r) => r.t === 'same').length;
  it('level 11: 5 clues, all needed, at most one direct match', () => {
    const f = minimalSets(sol, 5, (rs) => pairsUsed(rs) === 3 && sames(rs) <= 1, 6, 11);
    f.forEach((rs) => out('L11', rs));
  }, 600000);
  it('level 22: 6 clues, all needed, no direct match, nothing names Daniel as "same"', () => {
    const f = minimalSets(sol, 6, (rs) => pairsUsed(rs) === 3 && sames(rs) === 0, 6, 22);
    f.forEach((rs) => out('L22', rs));
  }, 600000);
});

// ---------- six CCTV frames with exactly one arrangement ----------
d('panels', () => {
  const OPP: Record<Edge, Edge> = { N: 'S', S: 'N', E: 'W', W: 'E' };
  const EDGES: Edge[] = ['N', 'E', 'S', 'W'];
  const pairs: [Edge, Edge][] = [];
  for (let a = 0; a < 4; a++) for (let b = a + 1; b < 4; b++) pairs.push([EDGES[a], EDGES[b]]);
  const rows = 3, cols = 2;
  const dir = (a: number, b: number): Edge => (b === a + 1 ? 'E' : b === a - 1 ? 'W' : b === a + cols ? 'S' : 'N');
  const nbr = (s: number) => { const r = Math.floor(s / cols), c = s % cols, o: number[] = []; if (r > 0) o.push(s - cols); if (r < rows - 1) o.push(s + cols); if (c > 0) o.push(s - 1); if (c < cols - 1) o.push(s + 1); return o; };
  const paths: number[][] = [];
  const walk = (p: number[]) => { if (p.length === rows * cols) { paths.push(p.slice()); return; } for (const x of nbr(p[p.length - 1])) if (!p.includes(x)) { p.push(x); walk(p); p.pop(); } };
  for (let s = 0; s < rows * cols; s++) walk([s]);
  const outward = (s: number): Edge[] => { const r = Math.floor(s / cols), c = s % cols, o: Edge[] = []; if (r === 0) o.push('N'); if (r === rows - 1) o.push('S'); if (c === 0) o.push('W'); if (c === cols - 1) o.push('E'); return o; };

  it('level 13: 2x3 frames, one arrangement in time order, at most 3 connecting traps', () => {
    const rand = rng(1313);
    let found = 0;
    for (let trial = 0; trial < 4000 && found < 3; trial++) {
      const path = paths[Math.floor(rand() * paths.length)];
      const startEdge = outward(path[0])[Math.floor(rand() * outward(path[0]).length)];
      const lastOut = outward(path[path.length - 1]);
      const endEdge = lastOut[Math.floor(rand() * lastOut.length)];
      const ids = ['p', 'q', 'g', 'b', 'r', 't'];
      let entry: Edge = startEdge;
      const panels: PanelsDef['panels'] = ids.map((id, k) => {
        const exit: Edge = k === path.length - 1 ? endEdge : dir(path[k], path[k + 1]);
        if (entry === exit) throw new Error('degenerate');
        const sol: [Edge, Edge] = [entry, exit];
        let other: [Edge, Edge];
        do { other = pairs[Math.floor(rand() * pairs.length)]; } while ((other.includes(sol[0]) && other.includes(sol[1])));
        entry = OPP[exit];
        const solFirst = rand() < 0.5;
        return { id, label: id, views: solFirst ? [{ name: 'wide', exits: sol, caption: '' }, { name: 'close', exits: other, caption: '' }] : [{ name: 'wide', exits: other, caption: '' }, { name: 'close', exits: sol, caption: '' }] } as PanelsDef['panels'][number];
      });
      const def: PanelsDef = { kind: 'panels', rows, cols, panels, start: { slot: path[0], edge: startEdge }, end: { slot: path[path.length - 1], edge: endEdge }, order: ids };
      let full = 0, ordered = 0;
      const perms = (xs: number[]): number[][] => (xs.length <= 1 ? [xs] : xs.flatMap((x, i) => perms([...xs.slice(0, i), ...xs.slice(i + 1)]).map((p) => [x, ...p])));
      for (const slots of perms([0, 1, 2, 3, 4, 5])) for (let m = 0; m < 64; m++) {
        const st = { slots, views: [0, 1, 2, 3, 4, 5].map((i) => (m >> i) & 1) };
        const seen = tracePanels(def, st);
        if (seen?.length === 6) { full++; if (seen.every((pi, k) => def.panels[pi].id === def.order[k])) ordered++; if (full > 4) break; }
      }
      if (ordered === 1 && full >= 2 && full <= 4) { found++; out('L13', { ...def, full }); }
    }
  }, 600000);
});

// ---------- water sort with a long shortest solution ----------
d('water', () => {
  it('level 17: 5 liquids, 7 tanks, 17 to 22 pours', () => {
    const cap = 4, colors = ['W', 'O', 'S', 'R', 'G'];
    const bfs = (start: string[]): number => {
      const key = (t: string[]) => t.slice().sort().join('|');
      let frontier = [start];
      const seen = new Set([key(start)]);
      for (let depth = 0; depth < 26 && frontier.length; depth++) {
        const next: string[][] = [];
        for (const t of frontier) {
          if (waterSolved(t, cap)) return depth;
          for (let a = 0; a < t.length; a++) for (let b = 0; b < t.length; b++) {
            if (!canPour(t, cap, a, b)) continue;
            const nt = pour(t, cap, a, b);
            const k = key(nt);
            if (!seen.has(k)) { seen.add(k); next.push(nt); }
          }
        }
        frontier = next;
      }
      return -1;
    };
    const rand = rng(1717);
    let found = 0;
    for (let trial = 0; trial < 120 && found < 3; trial++) {
      const units = shuffle(colors.flatMap((c) => Array(cap).fill(c) as string[]), rand);
      const tubes = [0, 1, 2, 3, 4].map((i) => units.slice(i * cap, (i + 1) * cap).join('')).concat(['', '']);
      if (tubes.slice(0, 5).some((t) => new Set(t).size === 1)) continue;
      const n = bfs(tubes);
      if (n >= 17 && n <= 22) { found++; out('L17', { tubes, pours: n }); }
    }
  }, 900000);
});

// ---------- tilt mazes ----------
d('tilt', () => {
  const make = (R: number, C: number, walls: number, holes: number, rand: () => number) => {
    const g = Array.from({ length: R }, (_, y) => Array.from({ length: C }, (_, x) => (y === 0 || x === 0 || y === R - 1 || x === C - 1 ? '#' : '.')));
    const free = () => { for (;;) { const y = 1 + Math.floor(rand() * (R - 2)), x = 1 + Math.floor(rand() * (C - 2)); if (g[y][x] === '.') return [y, x]; } };
    for (let i = 0; i < walls; i++) { const [y, x] = free(); g[y][x] = '#'; }
    for (let i = 0; i < holes; i++) { const [y, x] = free(); g[y][x] = 'O'; }
    g[1][1] = 'S';
    const [gy, gx] = free(); g[gy][gx] = 'G';
    return g.map((r) => r.join(''));
  };
  const search = (name: string, R: number, C: number, walls: number, holes: number, lo: number, hi: number, seed: number) => {
    const rand = rng(seed);
    let found = 0;
    for (let t = 0; t < 60000 && found < 3; t++) {
      const m = make(R, C, walls, holes, rand);
      const n = tiltSolve(m);
      if (n >= lo && n <= hi) { found++; out(name, { rows: m, tilts: n, path: tiltPath(m)!.join('') }); }
    }
  };
  it('level 24: 9x9, 11 to 14 tilts', () => search('L24', 9, 9, 16, 3, 11, 14, 24), 600000);
  it('level 21 stage: 6x6, 6 to 8 tilts', () => search('L21', 6, 6, 5, 2, 6, 8, 21), 600000);
  void find;
});

// ---------- lever grids (lights out) ----------
d('levers', () => {
  const search = (name: string, n: number, lo: number, seed: number) => {
    const rand = rng(seed);
    let found = 0;
    for (let t = 0; t < 400 && found < 3; t++) {
      let s = Array(n * n).fill(1);
      const presses = shuffle([...Array(n * n).keys()], rand).slice(0, Math.floor(n * n * 0.6));
      for (const i of presses) s = leverToggle(s, i);
      const k = leverSolve(s);
      if (k >= lo) { found++; out(name, { start: s, min: k }); }
    }
  };
  it('level 20: 3x3, at least 5 presses', () => search('L20', 3, 5, 20));
  it('level 25: 4x4, at least 8 presses', () => search('L25', 4, 8, 25), 600000);
});

// ---------- a larger path board that can't be guessed ----------
d('zip', () => {
  it('level 27: 7 rows x 6 cols, walls, 7 numbers, 1 or 2 solutions', () => {
    const R = 7, C = 6, rand = rng(2727);
    const nb = (i: number) => { const r = Math.floor(i / C), c = i % C, o: number[] = []; if (r > 0) o.push(i - C); if (r < R - 1) o.push(i + C); if (c > 0) o.push(i - 1); if (c < C - 1) o.push(i + 1); return o; };
    let found = 0;
    for (let trial = 0; trial < 3000 && found < 3; trial++) {
      const wallCount = 4 + Math.floor(rand() * 3);
      const walls = new Set<number>();
      while (walls.size < wallCount) walls.add(Math.floor(rand() * R * C));
      const open = [...Array(R * C).keys()].filter((i) => !walls.has(i));
      // Parity: a grid path alternates colours, so the counts may differ by at most one.
      const black = open.filter((i) => (Math.floor(i / C) + (i % C)) % 2 === 0).length;
      if (Math.abs(black - (open.length - black)) > 1) continue;
      // Random Hamiltonian path by depth-first search with a node budget.
      const start = open[Math.floor(rand() * open.length)];
      const seen = new Set([start]);
      const path = [start];
      let nodes = 0;
      const dfs = (): boolean => {
        if (path.length === open.length) return true;
        if (++nodes > 60000) return false;
        const head = path[path.length - 1];
        const opts = shuffle(nb(head).filter((j) => !walls.has(j) && !seen.has(j)), rand);
        for (const j of opts) {
          seen.add(j); path.push(j);
          // prune: every unvisited open cell must stay reachable
          const q = [j], mark = new Set([j]); let reach = 0;
          while (q.length) { const x = q.pop()!; for (const y of nb(x)) if (!walls.has(y) && !seen.has(y) && !mark.has(y)) { mark.add(y); reach++; q.push(y); } }
          if (reach === open.length - path.length && dfs()) return true;
          seen.delete(j); path.pop();
        }
        return false;
      };
      if (!dfs()) continue;
      const m = 7, len = path.length;
      const marks = [0];
      for (let k = 1; k < m - 1; k++) marks.push(Math.round((k * (len - 1)) / (m - 1) + (rand() * 4 - 2)));
      marks.push(len - 1);
      if (new Set(marks).size !== m || marks.some((x, i) => i > 0 && x <= marks[i - 1])) continue;
      const moves = path.slice(1).map((c, i) => { const p = path[i]; return c === p + 1 ? 'R' : c === p - 1 ? 'L' : c === p + C ? 'D' : 'U'; }).join('');
      const def = { kind: 'zip' as const, rows: R, cols: C, start: [Math.floor(start / C), start % C] as [number, number], moves, marks };
      const model = zipModel(def as never);
      const { count, exhausted } = countZipSolutions(model, 3, 4_000_000);
      if (!exhausted && count <= 2) { found++; out('L27', { ...def, solutions: count, walls: [...walls] }); }
    }
  }, 900000);
});
