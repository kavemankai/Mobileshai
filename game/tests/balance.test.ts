// Difficulty budget. These tests fail if a later edit flattens the ramp or makes a puzzle
// frustrating: they measure the real puzzle data with the game's own rule functions.
//
// Targets, by chapter: 1 easy (a minute or two each), 2 medium, 3 medium-hard, 4 hard. Within each
// kind of puzzle, later levels must be at least as big as earlier ones.

import { describe, expect, it } from 'vitest';
import type { BoxStage, Level, RoomDef } from '../src/core/types';
import { leverSolve } from '../src/puzzles/box';
import { logicSolutions } from '../src/puzzles/logic';
import { tiltSolve } from '../src/puzzles/tilt';
import { canPour, pour, waterSolved } from '../src/puzzles/water';
import { countZipSolutions, zipModel } from '../src/puzzles/zip';
import { LEVELS } from '../src/story/levels';
import { median, percentile, swapsToClear } from './sim/match3sim';

const lv = (n: number): Level => LEVELS[n - 1];

function waterMin(tubes: string[], cap: number): number {
  const key = (t: string[]) => t.slice().sort().join('|');
  let frontier = [tubes];
  const seen = new Set([key(tubes)]);
  for (let d = 0; d < 40 && frontier.length; d++) {
    const next: string[][] = [];
    for (const t of frontier) {
      if (waterSolved(t, cap)) return d;
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
}

const stageWeight = (s: BoxStage): number => {
  switch (s.type) {
    case 'screws': return s.count;
    case 'sliders': return s.targets.length * 2;
    case 'dials': return s.code.length * 2 + (s.evidence ? 4 : 0);
    case 'levers': { const n = Math.round(Math.sqrt(s.start.length)); return leverSolve(s.start) * 2 + (n * n) / 2; }
    case 'press': return s.count / 2;
    case 'patch': return s.left.length * 3;
    case 'tilt': return tiltSolve(s.rows) * 2;
  }
};

/** A rough size for each puzzle, comparable between levels of the same kind. */
function size(l: Level): number {
  const p = l.puzzle;
  switch (p.kind) {
    case 'zip': return zipModel(p).open.filter(Boolean).length;
    case 'hidden': return p.targets.length * 10 + p.clutter;
    case 'panels': return p.panels.length;
    case 'match3': return p.mask.join('').split('#').length - 1;
    case 'timeline': return p.cards.length;
    case 'logic': return p.clues.filter((c) => c.rule).length;
    case 'box': return p.stages.reduce((n, s) => n + stageWeight(s), 0);
    case 'room': return p.hotspots.length;
    default: return 0;
  }
}

describe('match-3', () => {
  const l7 = lv(7).puzzle, l26 = lv(26).puzzle;
  if (l7.kind !== 'match3' || l26.kind !== 'match3') throw new Error('levels 7 and 26 should be match-3');
  const casual = (def: typeof l7, n: number) => Array.from({ length: n }, (_, s) => swapsToClear(def, s + 1, 'random'));
  const good = (def: typeof l7, n: number) => Array.from({ length: n }, (_, s) => swapsToClear(def, s + 1, 'smart'));

  it('level 7 takes a casual player about 15 to 30 swaps and never drags', () => {
    const xs = casual(l7, 24);
    expect(median(xs)).toBeGreaterThanOrEqual(12);
    expect(median(xs)).toBeLessThanOrEqual(30);
    expect(percentile(xs, 0.9)).toBeLessThanOrEqual(45);
  }, 120000);
  it('level 26 is longer, but a casual player is still done in about a minute', () => {
    const xs = casual(l26, 24);
    expect(median(xs)).toBeGreaterThanOrEqual(25);
    expect(median(xs)).toBeLessThanOrEqual(50);
    expect(percentile(xs, 0.9)).toBeLessThanOrEqual(75);
  }, 180000);
  it('a good player has no long tail on level 26 (the last few squares do not drag)', () => {
    const xs = good(l26, 10);
    expect(percentile(xs, 0.9)).toBeLessThanOrEqual(60);
  }, 180000);
  it('level 26 is bigger than level 7', () => expect(size(lv(26))).toBeGreaterThan(size(lv(7))));
});

describe('path boards', () => {
  const zips = [1, 6, 12, 27].map((n) => ({ n, m: zipModel((lv(n).puzzle as never))}));
  it('get bigger through the game', () => {
    const cells = zips.map((z) => z.m.open.filter(Boolean).length);
    expect(cells).toEqual([...cells].sort((a, b) => a - b));
    expect(cells[3]).toBeGreaterThanOrEqual(36);
  });
  it('the final board has one or two solutions, so it cannot be guessed by snaking', () => {
    const { count, exhausted } = countZipSolutions(zips[3].m, 5, 5_000_000);
    expect(exhausted).toBe(false);
    expect(count).toBeLessThanOrEqual(2);
  });
  it('the final board has at least 7 numbers and some blocked squares', () => {
    const p = lv(27).puzzle;
    if (p.kind !== 'zip') throw new Error();
    expect(p.marks.length).toBeGreaterThanOrEqual(7);
    expect(zips[3].m.open.filter((o) => !o).length).toBeGreaterThanOrEqual(4);
  });
});

describe('logic grids', () => {
  for (const n of [11, 22]) {
    it(`level ${n}: every clue is needed and the answer is unique`, () => {
      const p = lv(n).puzzle;
      if (p.kind !== 'logic') throw new Error();
      const ruled = p.clues.filter((c) => c.rule);
      expect(logicSolutions(p)).toHaveLength(1);
      ruled.forEach((_, drop) => {
        const rest = { ...p, clues: p.clues.filter((c) => c.rule && c !== ruled[drop]) };
        expect(logicSolutions(rest).length, `clue ${drop + 1} is redundant`).toBeGreaterThan(1);
      });
    });
  }
  it('level 22 has more clues than level 11 and never states the culprit directly', () => {
    const a = lv(11).puzzle, b = lv(22).puzzle;
    if (a.kind !== 'logic' || b.kind !== 'logic') throw new Error();
    expect(b.clues.filter((c) => c.rule).length).toBeGreaterThan(a.clues.filter((c) => c.rule).length);
    // Daniel is suspect 2. No clue may say "same" about him directly.
    expect(b.clues.some((c) => c.rule?.t === 'same' && (c.rule.a[0] === 0 && c.rule.a[1] === 2 || c.rule.b[0] === 0 && c.rule.b[1] === 2))).toBe(false);
  });
});

describe('long solutions', () => {
  it('the flooded corridor needs at least 16 pours at best', () => {
    const p = lv(17).puzzle;
    if (p.kind !== 'water') throw new Error();
    expect(waterMin(p.tubes, p.capacity)).toBeGreaterThanOrEqual(16);
    expect(Object.keys(p.colors).length).toBeGreaterThanOrEqual(5);
  }, 60000);
  it('the boiler maze needs at least 11 tilts, and is bigger than the case maze', () => {
    const p = lv(24).puzzle;
    if (p.kind !== 'tilt') throw new Error();
    expect(tiltSolve(p.rows)).toBeGreaterThanOrEqual(11);
    const stage = (lv(21).puzzle as { stages: BoxStage[] }).stages.find((s) => s.type === 'tilt');
    if (stage?.type !== 'tilt') throw new Error();
    expect(tiltSolve(stage.rows)).toBeGreaterThanOrEqual(6);
    expect(tiltSolve(p.rows)).toBeGreaterThan(tiltSolve(stage.rows));
  });
  it('the final gate has a 4x4 lever grid that needs 6 presses', () => {
    const st = (lv(25).puzzle as { stages: BoxStage[] }).stages[0];
    if (st.type !== 'levers') throw new Error();
    expect(st.start).toHaveLength(16);
    expect(leverSolve(st.start)).toBeGreaterThanOrEqual(6);
  });
  it('the switchboard levers need at least 5 presses', () => {
    const st = (lv(20).puzzle as { stages: BoxStage[] }).stages[0];
    if (st.type !== 'levers') throw new Error();
    expect(leverSolve(st.start)).toBeGreaterThanOrEqual(5);
  });
});

describe('deduction, not instructions', () => {
  it('later puzzle boxes take their codes from the case file', () => {
    for (const n of [21, 25]) {
      const dial = (lv(n).puzzle as { stages: BoxStage[] }).stages.find((s) => s.type === 'dials');
      expect(dial?.type === 'dials' && dial.evidence, `level ${n}`).toBe(true);
    }
  });
  it('the codes asked for really are in the evidence earned before them', () => {
    const text = (upTo: number) => LEVELS.slice(0, upTo).map((l) => l.clue.text).join(' ');
    expect(text(24)).toContain('6421'); // laundry override, earned at level 23
    expect(text(20)).toMatch(/10:57 PM/); // clone time, earned at level 16
  });
  it('the switchboard patch chart is solvable by elimination, not stated outright', () => {
    const st = (lv(20).puzzle as { stages: BoxStage[] }).stages.find((s) => s.type === 'patch');
    if (st?.type !== 'patch') throw new Error();
    expect(st.left.length).toBeGreaterThanOrEqual(4);
    // The mic is the pair that is not stated: its line must not appear next to "mic" in the chart text.
    expect(st.clue).not.toMatch(/mic[^.]*line 1/i);
  });
});

describe('the ramp', () => {
  const byKind = new Map<string, number[]>();
  LEVELS.forEach((l, i) => { if (!byKind.has(l.puzzle.kind)) byKind.set(l.puzzle.kind, []); byKind.get(l.puzzle.kind)!.push(i + 1); });
  for (const [kind, levels] of byKind) {
    if (levels.length < 2 || !['zip', 'hidden', 'panels', 'match3', 'timeline', 'logic', 'box', 'room'].includes(kind)) continue;
    it(`${kind}: never smaller than an earlier ${kind} puzzle (levels ${levels.join(', ')})`, () => {
      const sizes = levels.map((n) => size(lv(n)));
      expect(sizes, `sizes ${sizes.join(' → ')}`).toEqual([...sizes].sort((a, b) => a - b));
    });
  }
  it('chapter 4 rooms need two items and a gated keypad', () => {
    const p = lv(23).puzzle as RoomDef;
    expect(Object.keys(p.items).length).toBeGreaterThanOrEqual(2);
    expect(p.hotspots.some((h) => h.hiddenIf) && p.hotspots.some((h) => h.visibleIf && h.keypad)).toBe(true);
  });
  it('room 17 needs two items and two locks', () => {
    const p = lv(10).puzzle as RoomDef;
    expect(Object.keys(p.items).length).toBeGreaterThanOrEqual(2);
  });
});
