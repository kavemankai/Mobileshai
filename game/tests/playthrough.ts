// Full legal-input playthrough. Plans each puzzle with the game's own rule functions, then
// solves it by tapping the real UI: no state poking, no skips. Records actions, time, sounds
// (and whether any fell back to synth), status messages, layout problems and screenshots.
//
// Usage: npm run build:single && npx vite-node tests/playthrough.ts
// Output: artifacts/playthrough/*.png and artifacts/playthrough/report.json

import { mkdirSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
import type { BoxStage, GoodsDef, Level, PanelsDef, RoomDef, WaterDef } from '../src/core/types';
import { rng } from '../src/core/rng';
import { derivePieces, normalize, rotate } from '../src/puzzles/blockfit';
import { leverToggle } from '../src/puzzles/box';
import { clearFull, goodsSolved, initRacks, type Racks } from '../src/puzzles/goods';
import { tracePanels } from '../src/puzzles/panels';
import { spotVisible, useSpot, type RoomState } from '../src/puzzles/room';
import { tiltPath } from '../src/puzzles/tilt';
import { canPour, pour, waterSolved } from '../src/puzzles/water';
import { zipModel } from '../src/puzzles/zip';
import { LEVELS } from '../src/story/levels';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
type Page = import('playwright').Page;

const OUT = resolve('artifacts/playthrough');
mkdirSync(OUT, { recursive: true });
const FILE = 'file://' + resolve('dist-single/index.html') + '?debug=1';

// ---------- planners ----------

function permutations<T>(xs: T[]): T[][] {
  if (xs.length <= 1) return [xs];
  return xs.flatMap((x, i) => permutations([...xs.slice(0, i), ...xs.slice(i + 1)]).map((p) => [x, ...p]));
}

function panelPlan(def: PanelsDef) {
  const n = def.panels.length;
  for (const slots of permutations([...Array(n).keys()])) for (let m = 0; m < 1 << n; m++) {
    const st = { slots, views: [...Array(n).keys()].map((i) => (m >> i) & 1) };
    const seen = tracePanels(def, st);
    if (seen && seen.length === n && seen.every((pi, k) => def.panels[pi].id === def.order[k])) return st;
  }
  throw new Error('no panel solution');
}

function waterPlan(def: WaterDef): [number, number][] {
  const key = (t: string[]) => t.join('|');
  const prev = new Map<string, [string, [number, number]]>();
  let frontier = [def.tubes];
  const seen = new Set([key(def.tubes)]);
  while (frontier.length) {
    const next: string[][] = [];
    for (const t of frontier) {
      if (waterSolved(t, def.capacity)) {
        const out: [number, number][] = [];
        for (let k = key(t); prev.has(k); k = prev.get(k)![0]) out.unshift(prev.get(k)![1]);
        return out;
      }
      for (let a = 0; a < t.length; a++) for (let b = 0; b < t.length; b++) {
        if (!canPour(t, def.capacity, a, b)) continue;
        const nt = pour(t, def.capacity, a, b);
        const k = key(nt);
        if (!seen.has(k)) { seen.add(k); prev.set(k, [key(t), [a, b]]); next.push(nt); }
      }
    }
    frontier = next;
  }
  throw new Error('no water solution');
}

function goodsPlan(def: GoodsDef): [number, number, number][] {
  // Depth-first on exact rack contents, memoised on order-insensitive state (any card can be
  // picked from a rack, so order within a rack doesn't change what's reachable).
  const key = (r: Racks) => r.map((x) => x.slice().sort().join('')).sort().join('|');
  const seen = new Set<string>();
  const path: [number, number, number][] = [];
  const dfs = (r: Racks): boolean => {
    if (goodsSolved(def, r)) return true;
    if (path.length > 40) return false;
    const k = key(r);
    if (seen.has(k)) return false;
    seen.add(k);
    for (let a = 0; a < r.length; a++) for (let s = 0; s < r[a].length; s++) for (let b = 0; b < r.length; b++) {
      if (a === b || r[b].length >= def.capacity) continue;
      const nr = r.map((x) => x.slice());
      const [card] = nr[a].splice(s, 1);
      nr[b].push(card);
      clearFull(nr, def.capacity);
      path.push([a, s, b]);
      if (dfs(nr)) return true;
      path.pop();
    }
    return false;
  };
  if (!dfs(initRacks(def))) throw new Error('no goods solution');
  return path;
}

function leverPlan(start: number[]): number[] {
  const N = start.length;
  let best: number[] | null = null;
  for (let mask = 0; mask < 1 << N; mask++) {
    let s = start;
    const presses: number[] = [];
    for (let i = 0; i < N; i++) if (mask & (1 << i)) { s = leverToggle(s, i); presses.push(i); }
    if (s.every(Boolean) && (!best || presses.length < best.length)) best = presses;
  }
  return best!;
}

// ---------- recording ----------

interface Report {
  n: number; title: string; kind: string; scene: string;
  solved: boolean; actions: number; ms: number;
  minSolution: string;
  sounds: Record<string, number>; synthFallbacks: string[];
  statuses: string[]; errors: string[]; overflow: boolean; smallTargets: number;
  note?: string;
}

async function act(page: Page, rep: Report, fn: () => Promise<unknown>) {
  await fn();
  rep.actions++;
  const st = (await page.locator('.status').textContent().catch(() => ''))?.trim();
  if (st && rep.statuses.at(-1) !== st) rep.statuses.push(st);
}

const tap = (page: Page, rep: Report, sel: string, nth = 0) => act(page, rep, () => page.locator(sel).nth(nth).click());
const tapRole = (page: Page, rep: Report, name: string | RegExp, exact = true) => act(page, rep, () => page.getByRole('button', { name, exact: typeof name === 'string' ? exact : undefined }).first().click());

async function solveBox(page: Page, rep: Report, stages: BoxStage[]) {
  for (const st of stages) {
    await page.waitForTimeout(st === stages[0] ? 50 : 800); // stage transition
    if (st.type === 'screws') for (let k = 1; k <= st.count; k++) await tapRole(page, rep, `Screw ${k}`);
    if (st.type === 'sliders') for (let i = 0; i < st.targets.length; i++) await tapRole(page, rep, `Set slider ${i + 1} to ${st.targets[i]}`);
    if (st.type === 'dials') {
      for (let i = 0; i < st.code.length; i++) {
        for (let k = 0; k < 10; k++) {
          const v = await page.locator('.bx-digit').nth(i).textContent();
          if (v === st.code[i]) break;
          await tapRole(page, rep, `Dial ${i + 1} up`);
        }
      }
    }
    if (st.type === 'levers') for (const i of leverPlan(st.start)) await tap(page, rep, '.bx-lever', i);
    if (st.type === 'press') await tapRole(page, rep, `Panel ${st.target + 1}`);
    if (st.type === 'patch') for (let i = 0; i < st.left.length; i++) { await tapRole(page, rep, st.left[i]); await tapRole(page, rep, st.right[st.pairs[i]]); }
    if (st.type === 'tilt') for (const d of tiltPath(st.rows)!) { await tapRole(page, rep, `Tilt ${({ U: 'up', D: 'down', L: 'left', R: 'right' })[d]}`); await page.waitForTimeout(450); }
  }
}

async function solveRoom(page: Page, rep: Report, def: RoomDef) {
  const st: RoomState = { flags: new Set(), items: new Set(), used: new Set() };
  for (let pass = 0; pass < 10 && !st.flags.has(def.goal); pass++) {
    for (const s of def.hotspots) {
      if (!spotVisible(s, st) || s.keypad || st.used.has(s.id)) continue;
      if (s.needs && !st.items.has(s.needs)) continue;
      if (s.needs) await act(page, rep, () => page.locator('.room-item', { hasText: def.items[s.needs!].label }).click());
      await tapRole(page, rep, s.label);
      useSpot(def, st, s, s.needs ?? null);
    }
    if (def.keypad && !st.flags.has(def.goal) && def.hotspots.every((s) => s.keypad || st.used.has(s.id) || !spotVisible(s, st) || (s.needs && !st.items.has(s.needs)))) {
      await tapRole(page, rep, 'Door keypad');
      for (const k of def.keypad.code) await tapRole(page, rep, k);
      await tapRole(page, rep, 'Enter');
      st.flags.add(def.keypad.sets);
    }
  }
}

async function solve(page: Page, rep: Report, l: Level, i: number) {
  const p = l.puzzle;
  switch (p.kind) {
    case 'zip': {
      const m = zipModel(p);
      rep.minSolution = `${m.solution.length} cells`;
      for (const c of m.solution) await tap(page, rep, '.zip-cell', c);
      break;
    }
    case 'hidden': {
      const n = await page.locator('.ho-target').count();
      rep.minSolution = `${n} items among ${p.clutter} decoys`;
      for (let k = 0; k < n; k++) await tap(page, rep, '.ho-target', k);
      break;
    }
    case 'panels': {
      const sol = panelPlan(p);
      rep.minSolution = 'arrangement + zooms';
      for (let s = 0; s < sol.slots.length; s++) {
        const want = p.panels[sol.slots[s]].label;
        const labels = await page.locator('.panel-face').evaluateAll((els) => els.map((e) => e.getAttribute('aria-label') ?? ''));
        const at = labels.findIndex((t) => t.startsWith(want + ','));
        if (at !== s) { await tap(page, rep, '.panel-face', at); await tap(page, rep, '.panel-face', s); }
      }
      for (let s = 0; s < sol.slots.length; s++) {
        const pi = sol.slots[s];
        const label = (await page.locator('.panel-face').nth(s).getAttribute('aria-label')) ?? '';
        const wantView = p.panels[pi].views[sol.views[pi]].name;
        if (!label.includes(`${wantView} view`)) await tap(page, rep, '.panel-zoom', s);
      }
      break;
    }
    case 'match3': {
      // Greedy bot reading the board from the DOM: first legal move each turn.
      let moves = 0;
      while (moves < 400) {
        if (await page.locator('.clue-card').count()) break;
        const board = await page.locator('.m3-tile').evaluateAll((els) => els.map((e) => (e.getAttribute('aria-label') ?? '').split(',')[0]));
        const n = p.size;
        if (board.length !== n * n) { await page.waitForTimeout(150); continue; }
        const cell = (r: number, c: number) => (r >= 0 && c >= 0 && r < n && c < n ? board[r * n + c].replace(' line clearer', '') : '?');
        let mv: [number, number] | null = null;
        const matches = (b: string[], i2: number) => {
          const r = Math.floor(i2 / n), c = i2 % n, t = b[i2];
          const g = (rr: number, cc: number) => (rr >= 0 && cc >= 0 && rr < n && cc < n ? b[rr * n + cc] : '?');
          let h = 1; for (let k = 1; g(r, c - k) === t; k++) h++; for (let k = 1; g(r, c + k) === t; k++) h++;
          let v = 1; for (let k = 1; g(r - k, c) === t; k++) v++; for (let k = 1; g(r + k, c) === t; k++) v++;
          return h >= 3 || v >= 3;
        };
        const plain = board.map((_, k) => cell(Math.floor(k / n), k % n));
        outer: for (let a = 0; a < n * n; a++) for (const b of [a + 1, a + n]) {
          if (b >= n * n || (b === a + 1 && b % n === 0)) continue;
          const t = plain.slice(); [t[a], t[b]] = [t[b], t[a]];
          if (matches(t, a) || matches(t, b)) { mv = [a, b]; break outer; }
        }
        if (!mv) { await page.waitForTimeout(300); moves++; continue; }
        await act(page, rep, () => page.locator('.m3-tile').nth(mv![0]).click());
        await act(page, rep, () => page.locator('.m3-tile').nth(mv![1]).click());
        moves++;
        await page.waitForTimeout(700);
      }
      rep.minSolution = `${moves} swaps (greedy bot)`;
      break;
    }
    case 'timeline': {
      const want = p.order.map((id) => p.cards.find((c) => c.id === id)!.title);
      for (let target = 0; target < want.length; target++) {
        for (let guard = 0; guard < 12; guard++) {
          const titles = await page.locator('.tl-body strong').allTextContents();
          const at = titles.indexOf(want[target]);
          if (at === target) break;
          await act(page, rep, () => page.locator('.tl-up').nth(at).click());
        }
      }
      rep.minSolution = `${want.length} cards`;
      await tapRole(page, rep, 'Check the order');
      break;
    }
    case 'logic': {
      const [A, B, C] = p.categories;
      rep.minSolution = `${p.clues.length} clues`;
      for (let a = 0; a < A.items.length; a++) {
        const [b, c] = p.solution[a];
        for (const other of [B.items[b], C.items[c]]) {
          const re = new RegExp('^' + A.items[a].replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ' and ' + other.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ':');
          const btn = page.getByRole('button', { name: re });
          const label = (await btn.getAttribute('aria-label')) ?? '';
          const clicks = label.endsWith('yes') ? 0 : label.endsWith('no') ? 1 : 2;
          for (let k = 0; k < clicks; k++) await act(page, rep, () => btn.click());
        }
      }
      if (p.accuse) await tapRole(page, rep, A.items[p.accuse.answer]);
      break;
    }
    case 'cryptex': {
      rep.minSolution = `${p.word.length} rings`;
      for (let r = 0; r < p.word.length; r++) for (let k = 0; k < p.rings[r].length; k++) {
        if ((await page.locator('.cx-letter').nth(r).textContent()) === p.word[r]) break;
        await tapRole(page, rep, `Ring ${r + 1} down`);
      }
      break;
    }
    case 'goods': {
      const plan = goodsPlan(p);
      rep.minSolution = `${plan.length} moves (first found, not shortest)`;
      for (const [a, s, b] of plan) {
        await act(page, rep, () => page.locator('.gs-rack').nth(a).locator('.gs-card').nth(s).click());
        await act(page, rep, () => page.locator('.gs-rack').nth(b).click());
        await page.waitForTimeout(330);
      }
      break;
    }
    case 'water': {
      const plan = waterPlan(p);
      rep.minSolution = `${plan.length} pours (shortest)`;
      for (const [a, b] of plan) { await tap(page, rep, '.ws-tube', a); await tap(page, rep, '.ws-tube', b); }
      break;
    }
    case 'blockfit': {
      const { pieces } = derivePieces(p);
      const rand = rng((i + 1) * 7919);
      const ks = pieces.map(() => Math.floor(rand() * 4));
      rep.minSolution = `${pieces.length} strips`;
      const C = p.solution[0].length;
      for (let k = 0; k < pieces.length; k++) {
        await tap(page, rep, '.bf-piece', 0); // placed in order, so the next strip is always first in the tray
        let shape = pieces[k].cells; for (let r = 0; r < ks[k]; r++) shape = rotate(shape);
        let turns = 0; while (JSON.stringify(shape) !== JSON.stringify(normalize(pieces[k].cells)) && turns < 4) { shape = rotate(shape); turns++; }
        for (let t = 0; t < turns; t++) await tapRole(page, rep, '⟳ Rotate strip');
        // Anchor: first cell in reading order of the piece in the solution grid.
        let ar = -1, ac = -1;
        outer: for (let r = 0; r < p.solution.length; r++) for (let c = 0; c < C; c++) if (p.solution[r][c] === pieces[k].id) { ar = r; ac = c; break outer; }
        await tap(page, rep, '.bf-cell', ar * C + ac);
      }
      break;
    }
    case 'tilt': {
      const path = tiltPath(p.rows)!;
      rep.minSolution = `${path.length} tilts (shortest)`;
      for (const d of path) { await tapRole(page, rep, `Tilt ${({ U: 'up', D: 'down', L: 'left', R: 'right' })[d]}`); await page.waitForTimeout(450); }
      break;
    }
    case 'box':
      rep.minSolution = `${p.stages.length} stages: ${p.stages.map((s) => s.type).join(', ')}`;
      await solveBox(page, rep, p.stages);
      break;
    case 'room':
      rep.minSolution = `${p.hotspots.length} hotspots, ${Object.keys(p.items).length} items${p.keypad ? ', keypad' : ''}`;
      await solveRoom(page, rep, p);
      break;
  }
}

// ---------- run ----------

const browser = await chromium.launch();
const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, hasTouch: true, deviceScaleFactor: 1 });
const page = await ctx.newPage();
const errors: string[] = [];
page.on('pageerror', (e: Error) => errors.push(e.message));
page.on('console', (m: { type(): string; text(): string }) => { if (m.type() === 'error' && !/manifest|icon\.svg|ERR_FILE_NOT_FOUND/.test(m.text())) errors.push(m.text()); });
await page.goto(FILE);
await page.getByRole('button', { name: /Begin your shift/ }).click(); // unlocks audio
await page.waitForTimeout(1500);

const reports: Report[] = [];
const only = process.env.ONLY ? process.env.ONLY.split(',').map(Number) : null;
for (let i = 0; i < LEVELS.length; i++) {
  if (only && !only.includes(i + 1)) continue;
  const l = LEVELS[i];
  const rep: Report = { n: i + 1, title: l.title, kind: l.puzzle.kind, scene: l.scene, solved: false, actions: 0, ms: 0, minSolution: '', sounds: {}, synthFallbacks: [], statuses: [], errors: [], overflow: false, smallTargets: 0 };
  const errBefore = errors.length;
  await page.evaluate((k) => (window as unknown as { __lci: { jump(n: number): void } }).__lci.jump(k), i);
  await page.waitForTimeout(250);
  const playedBefore = (await page.evaluate(() => (window as unknown as { __lci: { audio(): { played: unknown[] } } }).__lci.audio().played.length));
  rep.overflow = await page.evaluate(() => document.documentElement.scrollWidth > innerWidth + 1);
  rep.smallTargets = await page.evaluate(() => [...document.querySelectorAll('.board-root button, .board-root [role=button]')].filter((b) => { const r = b.getBoundingClientRect(); return r.width > 0 && (r.width < 36 || r.height < 36); }).length);
  const tag = String(i + 1).padStart(2, '0');
  await page.screenshot({ path: `${OUT}/${tag}-start.png`, fullPage: true });
  const t0 = Date.now();
  try {
    await solve(page, rep, l, i);
    await page.locator('.clue-card').waitFor({ timeout: 5000 });
    rep.solved = true;
  } catch (e) {
    rep.note = String(e).slice(0, 300);
  }
  rep.ms = Date.now() - t0;
  await page.waitForTimeout(450);
  await page.screenshot({ path: `${OUT}/${tag}-solved.png`, fullPage: true });
  const audio = await page.evaluate(() => (window as unknown as { __lci: { audio(): { played: { name: string; from: string }[] } } }).__lci.audio());
  const played = audio.played.slice(playedBefore);
  for (const s of played) { rep.sounds[s.name] = (rep.sounds[s.name] ?? 0) + 1; if (s.from === 'synth' && !rep.synthFallbacks.includes(s.name)) rep.synthFallbacks.push(s.name); }
  rep.errors = errors.slice(errBefore);
  reports.push(rep);
  console.log(`${tag} ${rep.solved ? 'SOLVED' : 'FAILED'} ${l.puzzle.kind.padEnd(9)} ${String(rep.actions).padStart(4)} taps ${String((rep.ms / 1000).toFixed(1)).padStart(5)}s  ${rep.minSolution}${rep.synthFallbacks.length ? '  synth:' + rep.synthFallbacks.join(',') : ''}${rep.overflow ? '  OVERFLOW' : ''}${rep.smallTargets ? `  small:${rep.smallTargets}` : ''}${rep.note ? '  ' + rep.note : ''}`);
  await page.evaluate(() => (window as unknown as { __lci: { closeOverlay(): void } }).__lci.closeOverlay());
}

writeFileSync(`${OUT}/report${only ? '-' + only.join('-') : ''}.json`, JSON.stringify(reports, null, 1));
console.log(`\n${reports.filter((r) => r.solved).length}/${reports.length} solved with legal input. JS errors: ${errors.length}`);
await browser.close();
