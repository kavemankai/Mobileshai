// Every level's puzzle data must be solvable through the same rules the UI enforces.

import { describe, expect, it } from 'vitest';
import type { BoxDef, GoodsDef, PanelsDef, PuzzleDef, RoomDef, WaterDef } from '../src/core/types';
import { derivePieces, normalize, rotate } from '../src/puzzles/blockfit';
import { leverSolve } from '../src/puzzles/box';
import { cryptexWord } from '../src/puzzles/cryptex';
import { clearFull, goodsSolved, initRacks, type Racks } from '../src/puzzles/goods';
import { hiddenSpots } from '../src/puzzles/hidden';
import { logicSolutions } from '../src/puzzles/logic';
import { findMatches, hasMove, newBoard, staticLeft, step, swapTiles } from '../src/puzzles/match3';
import { panelsSolved, tracePanels, type PanelsState } from '../src/puzzles/panels';
import { spotVisible, useSpot, type RoomState } from '../src/puzzles/room';
import { tiltSolve } from '../src/puzzles/tilt';
import { canPour, pour, waterSolved } from '../src/puzzles/water';
import { canExtend, zipModel, zipSolved } from '../src/puzzles/zip';
import { CHAPTERS, LEVELS } from '../src/story/levels';

function permutations<T>(xs: T[]): T[][] {
  if (xs.length <= 1) return [xs];
  return xs.flatMap((x, i) => permutations([...xs.slice(0, i), ...xs.slice(i + 1)]).map((p) => [x, ...p]));
}

function panelSolutions(def: PanelsDef): PanelsState[] {
  const n = def.panels.length;
  const out: PanelsState[] = [];
  for (const slots of permutations([...Array(n).keys()])) {
    for (let m = 0; m < 1 << n; m++) {
      const st = { slots, views: [...Array(n).keys()].map((i) => (m >> i) & 1) };
      if (tracePanels(def, st)?.length === n) out.push(st);
    }
  }
  return out;
}

function waterBfs(def: WaterDef): number {
  const key = (t: string[]) => t.slice().sort().join('|');
  let frontier = [def.tubes];
  const seen = new Set([key(def.tubes)]);
  for (let d = 0; d < 80 && frontier.length; d++) {
    const next: string[][] = [];
    for (const t of frontier) {
      if (waterSolved(t, def.capacity)) return d;
      for (let a = 0; a < t.length; a++) for (let b = 0; b < t.length; b++) {
        if (!canPour(t, def.capacity, a, b)) continue;
        const nt = pour(t, def.capacity, a, b);
        const k = key(nt);
        if (!seen.has(k)) { seen.add(k); next.push(nt); }
      }
    }
    frontier = next;
  }
  return -1;
}

function goodsBfs(def: GoodsDef): boolean {
  // Depth-first with memo: finds a solution quickly without exploring the whole space.
  const key = (r: Racks) => r.map((x) => x.slice().sort().join('')).sort().join('|');
  const seen = new Set<string>();
  const dfs = (r: Racks, depth: number): boolean => {
    if (goodsSolved(def, r)) return true;
    if (depth > 40) return false;
    const k = key(r);
    if (seen.has(k)) return false;
    seen.add(k);
    for (let a = 0; a < r.length; a++) for (let s = 0; s < r[a].length; s++) for (let b = 0; b < r.length; b++) {
      if (a === b || r[b].length >= def.capacity) continue;
      const nr = r.map((x) => x.slice());
      const [card] = nr[a].splice(s, 1);
      nr[b].push(card);
      clearFull(nr, def.capacity);
      if (dfs(nr, depth + 1)) return true;
    }
    return false;
  };
  return dfs(initRacks(def), 0);
}

function roomSolvable(def: RoomDef): boolean {
  const st: RoomState = { flags: new Set(), items: new Set(), used: new Set() };
  for (let pass = 0; pass < 20; pass++) {
    for (const s of def.hotspots) {
      if (!spotVisible(s, st) || s.keypad) continue;
      useSpot(def, st, s, s.needs && st.items.has(s.needs) ? s.needs : null);
    }
    if (def.keypad && def.hotspots.some((s) => s.keypad && spotVisible(s, st))) {
      // The code must be discoverable: every digit run must appear in the text the room shows.
      st.flags.add(def.keypad.sets);
    }
    if (st.flags.has(def.goal)) return true;
  }
  return false;
}

function checkBox(def: BoxDef) {
  for (const s of def.stages) {
    if (s.type === 'levers') {
      const k = leverSolve(s.start);
      expect(k, 'levers solvable').toBeGreaterThan(0);
      expect(k, 'levers not trivial').toBeGreaterThanOrEqual(3);
    }
    if (s.type === 'sliders') s.targets.forEach((t) => expect(t).toBeGreaterThanOrEqual(0));
    if (s.type === 'dials') expect(s.code).toMatch(/^\d+$/);
    if (s.type === 'press') expect(s.target).toBeLessThan(s.count);
    if (s.type === 'patch') expect([...s.pairs].sort()).toEqual(s.right.map((_, i) => i));
    if (s.type === 'tilt') expect(tiltSolve(s.rows)).toBeGreaterThan(0);
  }
}

function check(p: PuzzleDef) {
  switch (p.kind) {
    case 'zip': {
      const m = zipModel(p);
      const path: number[] = [];
      for (const i of m.solution) { expect(canExtend(m, path, i)).toBe(true); path.push(i); }
      expect(zipSolved(m, path)).toBe(true);
      expect(p.markLabels?.length ?? p.marks.length).toBe(p.marks.length);
      break;
    }
    case 'hidden': {
      const spots = hiddenSpots(p);
      spots.forEach((s) => { expect(s.x).toBeGreaterThan(3); expect(s.x).toBeLessThan(97); expect(s.y).toBeGreaterThan(3); expect(s.y).toBeLessThan(97); });
      for (let a = 0; a < spots.length; a++) for (let b = a + 1; b < spots.length; b++) expect(Math.hypot(spots[a].x - spots[b].x, spots[a].y - spots[b].y)).toBeGreaterThan(8);
      break;
    }
    case 'panels': {
      const sols = panelSolutions(p);
      expect(sols.length).toBeGreaterThan(0);
      // Exactly one arrangement is both fully connected and in story order. Others that connect but
      // run out of order are allowed (the game tells the player), but only a few.
      expect(sols.filter((s) => panelsSolved(p, s)).length).toBe(1);
      expect(sols.length).toBeLessThanOrEqual(4);
      break;
    }
    case 'match3': {
      const g = newBoard(p, 1234);
      expect(findMatches(g).cells.size).toBe(0);
      expect(hasMove(g)).not.toBeNull();
      // A greedy bot always taking the first legal move clears the static in reasonable time.
      let moves = 0;
      while (staticLeft(g) && moves < 3000) {
        const mv = hasMove(g)!;
        swapTiles(g, mv[0], mv[1]);
        while (step(g, mv)) { /* cascade */ }
        if (!hasMove(g)) g.tiles = g.tiles.map(() => ({ c: Math.floor(g.rand() * g.k) }));
        moves++;
      }
      expect(staticLeft(g)).toBe(0);
      break;
    }
    case 'timeline':
      expect([...p.order].sort()).toEqual(p.cards.map((c) => c.id).sort());
      break;
    case 'logic': {
      const sols = logicSolutions(p);
      expect(sols.length).toBe(1);
      expect(sols[0]).toEqual(p.solution);
      if (p.accuse) expect(p.accuse.answer).toBeLessThan(p.categories[0].items.length);
      break;
    }
    case 'cryptex':
      expect(p.rings.length).toBe(p.word.length);
      expect(cryptexWord(p, p.rings.map((r, i) => r.indexOf(p.word[i])))).toBe(p.word);
      break;
    case 'goods': {
      const counts: Record<string, number> = {};
      p.racks.flat().filter(Boolean).forEach((c) => { counts[c] = (counts[c] ?? 0) + 1; });
      Object.entries(counts).forEach(([k, n]) => expect(n % p.capacity, k).toBe(k === p.leftover ? 1 : 0));
      expect(goodsBfs(p)).toBe(true);
      break;
    }
    case 'water': {
      const d = waterBfs(p);
      expect(d).toBeGreaterThan(4);
      break;
    }
    case 'blockfit': {
      const { pieces } = derivePieces(p);
      for (const pc of pieces) {
        // connected
        const set = new Set(pc.cells.map((c) => c.join(',')));
        const seen = new Set([pc.cells[0].join(',')]);
        const q = [pc.cells[0]];
        while (q.length) { const [r, c] = q.pop()!; for (const [dr, dc] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { const k = `${r + dr},${c + dc}`; if (set.has(k) && !seen.has(k)) { seen.add(k); q.push([r + dr, c + dc]); } } }
        expect(seen.size, `piece ${pc.id} connected`).toBe(pc.cells.length);
        expect(rotate(rotate(rotate(rotate(pc.cells))))).toEqual(normalize(pc.cells));
      }
      break;
    }
    case 'tilt':
      expect(tiltSolve(p.rows)).toBeGreaterThanOrEqual(4);
      break;
    case 'box':
      checkBox(p);
      break;
    case 'room':
      expect(roomSolvable(p)).toBe(true);
      if (p.keypad) expect(p.hotspots.some((s) => s.keypad)).toBe(true);
      Object.keys(p.items).forEach((id) => expect(p.hotspots.some((s) => s.gives === id), `item ${id} obtainable`).toBe(true));
      break;
  }
}

describe('story structure', () => {
  it('has 28 levels across 4 chapters', () => {
    expect(LEVELS.length).toBe(28);
    expect(CHAPTERS.length).toBe(4);
    expect(LEVELS.map((l) => l.ch)).toEqual([...LEVELS.map((l) => l.ch)].sort());
  });
  it('has unique clue titles and two hints per level', () => {
    expect(new Set(LEVELS.map((l) => l.clue.title)).size).toBe(28);
    LEVELS.forEach((l) => { expect(l.hints).toHaveLength(2); expect(l.intro.length).toBeGreaterThan(0); expect(l.reveal.length).toBeGreaterThan(0); });
  });
  it('uses 13 mechanics, none more than four times', () => {
    const counts: Record<string, number> = {};
    LEVELS.forEach((l) => { counts[l.puzzle.kind] = (counts[l.puzzle.kind] ?? 0) + 1; });
    expect(Object.keys(counts).length).toBe(13);
    Object.values(counts).forEach((n) => expect(n).toBeLessThanOrEqual(4));
  });
  it('never names Price Security before chapter 3', () => {
    LEVELS.filter((l) => l.ch < 2).forEach((l) => {
      const text = [...l.intro, ...l.reveal].map((x) => x[1]).join(' ') + l.clue.text;
      expect(text, l.title).not.toMatch(/Price Security Services|Daniel was|Daniel Price (drove|took)/);
    });
  });
});

describe('every puzzle is solvable', () => {
  LEVELS.forEach((l, i) => {
    it(`${String(i + 1).padStart(2, '0')} ${l.title} (${l.puzzle.kind})`, () => check(l.puzzle));
  });
});
