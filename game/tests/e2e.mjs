// End-to-end check of the single-file build in Chromium.
// 1. Full 28-level walkthrough with developer skips: every intro, puzzle, clue and reveal renders.
// 2. Every puzzle fits a 360px phone without horizontal scrolling.
// 3. Legal-input solves for several mechanics (real taps, no state poking).
// 4. Save and resume across a reload.
// Usage: npm run build:single && node tests/e2e.mjs   (screenshots go to artifacts/)

import { createRequire } from 'node:module';
import { mkdirSync } from 'node:fs';
import { resolve } from 'node:path';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const FILE = 'file://' + resolve('dist-single/index.html');
const SHOTS = resolve('artifacts');
mkdirSync(SHOTS, { recursive: true });

const results = [];
const ok = (name, pass, detail = '') => { results.push({ name, pass, detail }); console.log(`${pass ? 'PASS' : 'FAIL'}  ${name}${detail ? '  · ' + detail : ''}`); };

const browser = await chromium.launch();

async function newPage(width = 390, height = 844) {
  const ctx = await browser.newContext({ viewport: { width, height }, hasTouch: true, deviceScaleFactor: 1 });
  const page = await ctx.newPage();
  page.errors = [];
  page.on('pageerror', (e) => page.errors.push(e.message));
  page.on('console', (m) => { if (m.type() === 'error' && !/manifest|icon\.svg|ERR_FILE_NOT_FOUND/.test(m.text())) page.errors.push(m.text()); });
  return page;
}

const hook = (page, fn, arg) => page.evaluate(([f, a]) => window.__lci[f](a), [fn, arg]);
const state = (page) => page.evaluate(() => window.__lci.state());
const levelData = (page, i) => page.evaluate((k) => window.__lci.level(k), i);
const esc = (t) => t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/** Ticks a logic grid from the level data: the real buttons, ✗ then ✓ as a player would. */
async function tickLogic(page, def) {
  const [A, B, C] = def.categories;
  for (let a = 0; a < A.items.length; a++) {
    const [b, c] = def.solution[a];
    for (const other of [B.items[b], C.items[c]]) {
      const btn = page.getByRole('button', { name: new RegExp('^' + esc(A.items[a]) + ' and ' + esc(other) + ':') });
      const label = (await btn.getAttribute('aria-label')) ?? '';
      const clicks = label.endsWith('yes') ? 0 : label.endsWith('no') ? 1 : 2;
      for (let k = 0; k < clicks; k++) await btn.click();
    }
  }
}

/** Shortest tilt sequence, same rules as the game: the ball rolls until a wall, and has to stop on G. */
function tiltPath(rows) {
  const D = { U: [-1, 0], D: [1, 0], L: [0, -1], R: [0, 1] };
  let S, G;
  rows.forEach((r, y) => { const x = r.indexOf('S'); if (x >= 0) S = [y, x]; const g = r.indexOf('G'); if (g >= 0) G = [y, g]; });
  const roll = (from, d) => {
    let [y, x] = from; const path = [];
    for (;;) { const ny = y + D[d][0], nx = x + D[d][1]; const ch = rows[ny]?.[nx]; if (ch === undefined || ch === '#') return { path, hole: false }; y = ny; x = nx; path.push([y, x]); if (ch === 'O') return { path, hole: true }; }
  };
  const key = (p) => p.join(','); const prev = new Map(); const seen = new Set([key(S)]); let frontier = [S];
  while (frontier.length) {
    const next = [];
    for (const p of frontier) for (const d of 'UDLR') {
      const { path, hole } = roll(p, d);
      if (!path.length || hole) continue;
      const end = path[path.length - 1];
      if (seen.has(key(end))) continue;
      seen.add(key(end)); prev.set(key(end), [key(p), d]); next.push(end);
      if (end[0] === G[0] && end[1] === G[1]) { const out = []; for (let k = key(end); prev.has(k); k = prev.get(k)[0]) out.unshift(prev.get(k)[1]); return out; }
    }
    frontier = next;
  }
  return null;
}

/** Relative luminance contrast between a button's text and its own background. */
const contrastOf = (page, selector) => page.evaluate((sel) => {
  const lum = (rgb) => { const [r, g, b] = rgb.map((v) => { const c = v / 255; return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4; }); return 0.2126 * r + 0.7152 * g + 0.0722 * b; };
  const parse = (c) => (c.match(/[\d.]+/g) || []).slice(0, 3).map(Number);
  return [...document.querySelectorAll(sel)].map((el) => {
    const cs = getComputedStyle(el);
    const fg = lum(parse(cs.color)), bg = lum(parse(cs.backgroundColor));
    return { text: el.textContent.trim().slice(0, 14), ratio: +((Math.max(fg, bg) + 0.05) / (Math.min(fg, bg) + 0.05)).toFixed(1) };
  });
}, selector);


// ---------- 1 + 2: full walkthrough ----------
{
  const page = await newPage();
  await page.goto(FILE + '?debug=1');
  await page.getByRole('button', { name: /Begin your shift/ }).click();
  await page.locator('.name-input').fill('Jo');
  await page.getByRole('button', { name: 'Start the shift' }).click();
  ok('chapter card after name', await page.locator('.chapter').isVisible());

  let levels = 0, overflow = [];
  for (let i = 0; i < 28; i++) {
    let s = await state(page);
    if (s.phase === 'chapter') { await page.locator('.chapter').click(); s = await state(page); }
    if (s.phase !== 'intro') { ok(`level ${i + 1} reaches intro`, false, s.phase); break; }
    // Tap through every intro line for real.
    let guard = 0;
    while ((await state(page)).phase === 'intro' && guard++ < 30) await page.locator('.dialogue').click();
    if ((await state(page)).phase !== 'puzzle') { ok(`level ${i + 1} puzzle opens`, false); break; }
    const hasBoard = await page.locator('.board-root > *').count();
    const wide = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth + 1);
    if (wide) overflow.push(i + 1);
    if ([0, 1, 2, 3, 6, 8, 10, 14, 15, 16, 18, 19, 23].includes(i)) await page.screenshot({ path: `${SHOTS}/puzzle-${String(i + 1).padStart(2, '0')}.png` });
    if (!hasBoard) { ok(`level ${i + 1} board renders`, false); break; }
    await page.getByRole('button', { name: 'DEV skip' }).click();
    await page.locator('.clue-card').waitFor();
    if (i === 0) { await page.waitForTimeout(400); await page.screenshot({ path: `${SHOTS}/clue-card.png` }); }
    await page.getByRole('button', { name: 'Continue' }).click();
    guard = 0;
    while ((await state(page)).phase === 'reveal' && guard++ < 30) await page.locator('.dialogue').click();
    levels++;
  }
  const end = await state(page);
  ok('full walkthrough reaches the ending', end?.phase === 'end' && end.finished, `${levels}/28 levels, ${end?.clues.length} clues`);
  ok('all 28 clues earned', end?.clues.length === 28);
  ok('no horizontal scroll on puzzles at 390px', overflow.length === 0, overflow.join(','));
  await page.screenshot({ path: `${SHOTS}/ending.png` });
  ok('no JS errors in walkthrough', page.errors.length === 0, page.errors.slice(0, 3).join(' | '));
  await page.context().close();
}

// ---------- 2b: every puzzle at 360px ----------
{
  const page = await newPage(360, 740);
  await page.goto(FILE + '?debug=1');
  const bad = [];
  for (let i = 0; i < 28; i++) {
    await hook(page, 'jump', i);
    await page.waitForTimeout(60);
    const wide = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth + 1);
    const smallTargets = await page.evaluate(() => [...document.querySelectorAll('.board-root button')].filter((b) => { const r = b.getBoundingClientRect(); return r.width > 0 && (r.width < 34 || r.height < 34); }).length);
    if (wide || smallTargets > 0) bad.push(`${i + 1}${wide ? ' wide' : ''}${smallTargets ? ` ${smallTargets} small` : ''}`);
  }
  ok('every puzzle fits 360px and has controls of at least 34px', bad.length === 0, bad.join('; '));
  ok('no JS errors at 360px', page.errors.length === 0, page.errors.slice(0, 3).join(' | '));
  await page.context().close();
}

// ---------- 3: legal-input solves ----------
async function solved(page) {
  await page.locator('.clue-card').waitFor({ timeout: 4000 });
  return true;
}
{
  const page = await newPage();
  await page.goto(FILE + '?debug=1');

  // Zip, level 1: tap the snake.
  await hook(page, 'jump', 0);
  const snake = [0, 1, 2, 3, 7, 6, 5, 4, 8, 9, 10, 11, 15, 14, 13, 12];
  for (const i of snake) await page.locator('.zip-cell').nth(i).click();
  ok('zip solves by tapping', await solved(page).catch(() => false));

  // Room, level 5: torch, alcove, screwdriver, reader.
  await hook(page, 'jump', 4);
  await page.getByRole('button', { name: 'Fuse cupboard' }).click();
  await page.getByRole('button', { name: 'Dark alcove' }).click();
  const blocked = await page.locator('.room-msg').textContent();
  await page.getByRole('button', { name: /^Torch/ }).click();
  await page.getByRole('button', { name: 'Dark alcove' }).click();
  await page.getByRole('button', { name: /^Screwdriver/ }).click();
  await page.getByRole('button', { name: 'Access reader' }).click();
  ok('escape room solves with items', await solved(page).catch(() => false), `blocked text: "${blocked?.slice(0, 40)}…"`);

  // Room + keypad, level 9.
  await hook(page, 'jump', 8);
  await page.getByRole('button', { name: 'Door keypad' }).click();
  for (const k of ['1', '2', '3', '4']) await page.getByRole('button', { name: k, exact: true }).click();
  await page.getByRole('button', { name: 'Enter' }).click();
  const still = (await state(page)).phase === 'puzzle';
  for (const k of ['1', '7', '1', '8']) await page.getByRole('button', { name: k, exact: true }).click();
  await page.getByRole('button', { name: 'Enter' }).click();
  ok('keypad rejects wrong code and accepts 1718', still && await solved(page).catch(() => false));

  // Logic grid, level 11: tick the solution from the level data.
  await hook(page, 'jump', 10);
  await tickLogic(page, await levelData(page, 10));
  ok('logic grid solves by ticking', await solved(page).catch(() => false));

  // Accusation, level 22: grid, then the wrong name first. The buttons must be readable.
  await hook(page, 'jump', 21);
  const def22 = await levelData(page, 21);
  await tickLogic(page, def22);
  await page.getByRole('button', { name: 'Owen', exact: true }).waitFor();
  const accuseContrast = await contrastOf(page, '.lg-accuse .btn');
  ok('accusation buttons are readable (contrast at least 4.5)', accuseContrast.length === 3 && accuseContrast.every((c) => c.ratio >= 4.5), JSON.stringify(accuseContrast));
  await page.getByRole('button', { name: 'Owen', exact: true }).click();
  const wrong = await page.locator('.status').textContent();
  await page.getByRole('button', { name: 'Daniel', exact: true }).click();
  ok('accusation rejects Owen, accepts Daniel', /phone/.test(wrong ?? '') && await solved(page).catch(() => false));

  // Cryptex, level 15: turn each ring to the right letter.
  await hook(page, 'jump', 14);
  const word = 'KESTREL';
  for (let r = 0; r < word.length; r++) {
    for (let k = 0; k < 8; k++) {
      const letter = await page.locator('.cx-letter').nth(r).textContent();
      if (letter === word[r]) break;
      await page.getByRole('button', { name: `Ring ${r + 1} down` }).click();
    }
  }
  ok('cryptex opens on KESTREL', await solved(page).catch(() => false));

  // Puzzle box, level 3: screws, sliders, clean panel.
  await hook(page, 'jump', 2);
  for (let k = 1; k <= 4; k++) await page.getByRole('button', { name: `Screw ${k}`, exact: true }).click();
  await page.locator('.bx-sliders').waitFor();
  for (const [i, v] of [[1, 3], [2, 1], [3, 4]]) await page.getByRole('button', { name: `Set slider ${i} to ${v}` }).click();
  await page.locator('.bx-rivets').waitFor();
  await page.getByRole('button', { name: 'Panel 5', exact: true }).click();
  ok('puzzle box opens in three stages', await solved(page).catch(() => false));

  // Tilt maze, level 24: the shortest route, found from the level data, tapped on the arrow buttons.
  await hook(page, 'jump', 23);
  const route = tiltPath((await levelData(page, 23)).rows);
  for (const d of route) {
    await page.getByRole('button', { name: `Tilt ${({ U: 'up', D: 'down', L: 'left', R: 'right' })[d]}` }).click();
    await page.waitForTimeout(450);
  }
  ok(`tilt maze solves in ${route.length} tilts`, await solved(page).catch(() => false));

  // Path boards: tapping the real squares must work all the way down the board (levels 6, 12, 27).
  for (const idx of [5, 11, 26]) {
    await hook(page, 'jump', idx);
    const def = await levelData(page, idx);
    const cols = def.cols, moves = def.moves; let [r, c] = def.start; const cells = [r * cols + c];
    for (const m of moves) { if (m === 'R') c++; if (m === 'L') c--; if (m === 'U') r--; if (m === 'D') r++; cells.push(r * cols + c); }
    for (const i of cells) await page.locator('.zip-cell').nth(i).click();
    ok(`path board ${idx + 1} solves by tapping every square (${cells.length})`, await solved(page).catch(() => false));
  }

  // Hints and skip, no penalty.
  await hook(page, 'jump', 5);
  await page.getByRole('button', { name: 'Hint 1' }).click();
  await page.getByRole('button', { name: 'Hint 2' }).click();
  await page.getByRole('button', { name: 'Skip puzzle' }).click();
  await page.getByRole('button', { name: 'Skip it' }).click();
  ok('two hints then a penalty-free skip', await solved(page).catch(() => false));

  ok('no JS errors in legal-input solves', page.errors.length === 0, page.errors.slice(0, 3).join(' | '));
  await page.context().close();
}

// ---------- 4: save and resume ----------
{
  const page = await newPage();
  await page.goto(FILE);
  ok('developer tools hidden by default', (await page.evaluate(() => typeof window.__lci)) === 'undefined');
  await page.getByRole('button', { name: /Begin your shift/ }).click();
  await page.locator('.name-input').fill('Sam');
  await page.getByRole('button', { name: 'Start the shift' }).click();
  await page.locator('.chapter').click();
  for (let k = 0; k < 3; k++) await page.locator('.dialogue').click();
  await page.reload();
  await page.getByRole('button', { name: /Continue · Chapter 1/ }).click();
  const tap = await page.locator('.tap-hint').textContent();
  ok('resume returns to the same dialogue line', /4\/9/.test(tap ?? ''), tap ?? '');
  const name = await page.evaluate(() => JSON.parse(localStorage.getItem('last-check-in-save-v2')).name);
  ok('player name saved', name === 'Sam');
  await page.screenshot({ path: `${SHOTS}/story.png` });
  await page.context().close();
}

// ---------- 5: assets: audio plays from files, every image loads ----------
{
  const page = await newPage();
  await page.goto(FILE + '?debug=1');
  await page.getByRole('button', { name: /Begin your shift/ }).click(); // first tap unlocks audio
  await page.waitForTimeout(1500);
  let a = await hook(page, 'audio');
  ok('title plays file music and room tone', a.music === 'title' && a.ambience === 'exterior', JSON.stringify({ music: a.music, ambience: a.ambience, state: a.state }));
  ok('all effects and stingers decoded', a.effectsDecoded === a.files.sfx && a.stingersDecoded === a.files.stingers && a.files.sfx === 22, `${a.effectsDecoded}/${a.files.sfx} sfx, ${a.stingersDecoded}/${a.files.stingers} stingers`);
  await page.locator('.name-input').fill('Jo');
  await page.getByRole('button', { name: 'Start the shift' }).click();
  await page.waitForTimeout(2000);
  a = await hook(page, 'audio');
  ok('chapter 1 switches to investigation score and reception tone', a.music === 'investigation' && a.ambience === 'reception', JSON.stringify({ music: a.music, ambience: a.ambience }));
  await hook(page, 'jump', 23);
  await page.waitForTimeout(2000);
  a = await hook(page, 'audio');
  ok('chapter 4 laundry uses pressure score and laundry tone', a.music === 'pressure' && a.ambience === 'laundry', JSON.stringify({ music: a.music, ambience: a.ambience }));

  const broken = [];
  for (let i = 0; i < 28; i++) {
    await hook(page, 'jump', i);
    await page.waitForTimeout(80);
    const bad = await page.evaluate(async () => {
      const imgs = [...document.querySelectorAll('img')];
      await Promise.all(imgs.map((im) => (im.complete ? 0 : new Promise((r) => { im.onload = im.onerror = r; }))));
      return imgs.filter((im) => !im.naturalWidth).map((im) => im.className || im.src.slice(0, 40));
    });
    if (bad.length) broken.push(`${i + 1}: ${bad.join(',')}`);
  }
  ok('every image on every puzzle loads', broken.length === 0, broken.join(' | '));
  for (const [i, n] of [[1, 'hidden-reception'], [3, 'panels-cctv'], [4, 'room-items'], [6, 'match3-tiles']]) {
    await hook(page, 'jump', i);
    if (i === 4) { await page.getByRole('button', { name: 'Fuse cupboard' }).click(); }
    await page.waitForTimeout(150);
    await page.screenshot({ path: `${SHOTS}/asset-${n}.png` });
  }
  ok('no JS errors with assets', page.errors.length === 0, page.errors.slice(0, 3).join(' | '));
  await page.context().close();
}

// Story screens with portraits (moods)
{
  const page = await newPage();
  await page.goto(FILE + '?debug=1');
  await page.evaluate(() => { localStorage.setItem('last-check-in-save-v2', JSON.stringify({ v: 2, name: 'Jo', level: 24, phase: 'intro', line: 1, clues: [], hints: {}, finished: false })); });
  await page.reload();
  await page.getByRole('button', { name: /Continue/ }).click();
  await page.waitForTimeout(400);
  const src = await page.evaluate(() => document.querySelector('.portrait')?.className);
  ok('mood portrait shown as a cutout', /cutout/.test(src ?? ''), src ?? 'no portrait');
  await page.screenshot({ path: `${SHOTS}/story-nina-relieved.png` });
  await page.context().close();
}

// ---------- 6: the audited bugs stay fixed ----------
{
  const page = await newPage();
  await page.goto(FILE + '?debug=1');

  // Paper boards: every button on a paper board has readable text.
  const bad = [];
  for (const idx of [7, 10, 17, 18, 21, 27]) {
    await hook(page, 'jump', idx);
    const rows = await contrastOf(page, '.board-frame.paper button:not(.lg-cell):not(.bf-cell):not(.bf-piece):not(.tl-arrows button)');
    rows.filter((r) => r.ratio < 4.5).forEach((r) => bad.push(`L${idx + 1} "${r.text}" ${r.ratio}`));
  }
  ok('buttons on paper boards are readable', bad.length === 0, bad.join('; '));

  // Timeline: the page scrolls over cards. Only the handle captures touch.
  await hook(page, 'jump', 27);
  const ta = await page.evaluate(() => ({ list: getComputedStyle(document.querySelector('.tl-list')).touchAction, card: getComputedStyle(document.querySelector('.tl-card')).touchAction, grip: getComputedStyle(document.querySelector('.tl-grip')).touchAction }));
  ok('timeline cards let the page scroll, handles do not', ta.list === 'auto' && ta.card === 'auto' && ta.grip === 'none', JSON.stringify(ta));
  const arrow = await page.locator('.tl-up').nth(1).boundingBox();
  ok('timeline arrows are at least 40px tall and 44px wide', arrow.height >= 40 && arrow.width >= 44, `${arrow.width}x${arrow.height}`);
  // Dragging the handle moves a card; tapping elsewhere on it selects, never drags.
  const before = await page.locator('.tl-body strong').allTextContents();
  const grip = await page.locator('.tl-grip').nth(0).boundingBox();
  await page.mouse.move(grip.x + grip.width / 2, grip.y + grip.height / 2);
  await page.mouse.down(); await page.mouse.move(grip.x + grip.width / 2, grip.y + grip.height / 2 + 190, { steps: 6 }); await page.mouse.up();
  const after = await page.locator('.tl-body strong').allTextContents();
  ok('dragging a timeline handle reorders the cards', before[0] !== after[0] && after.includes(before[0]), `${before[0]} -> ${after.indexOf(before[0]) + 1}`);

  // Match-3: clearing the static shows the frame and holds it before the evidence card.
  await hook(page, 'jump', 6);
  const t0 = Date.now(); let clearedAt = 0, cardAt = 0;
  const n = 7;
  for (let moves = 0; moves < 120 && !cardAt; moves++) {
    if (!clearedAt && (await page.locator('.m3-stack.cleared').count())) clearedAt = Date.now();
    if (await page.locator('.clue-card').count()) { cardAt = Date.now(); break; }
    if (clearedAt) { await page.waitForTimeout(150); continue; }
    const labels = await page.locator('.m3-tile').evaluateAll((els) => els.map((e) => (e.getAttribute('aria-label') ?? '').split(',')[0].replace(' line clearer', '')));
    const stat = await page.locator('.m3-cell').evaluateAll((els) => els.map((e) => e.classList.contains('static')));
    if (labels.length !== n * n) { await page.waitForTimeout(120); continue; }
    const runs = (b, i) => { const r = Math.floor(i / n), c = i % n, t = b[i], out = []; const g = (rr, cc) => (rr >= 0 && cc >= 0 && rr < n && cc < n ? b[rr * n + cc] : '?'); let h = [i]; for (let k = 1; g(r, c - k) === t; k++) h.push(r * n + c - k); for (let k = 1; g(r, c + k) === t; k++) h.push(r * n + c + k); if (h.length >= 3) out.push(...h); let v = [i]; for (let k = 1; g(r - k, c) === t; k++) v.push((r - k) * n + c); for (let k = 1; g(r + k, c) === t; k++) v.push((r + k) * n + c); if (v.length >= 3) out.push(...v); return out; };
    let best = null, bs = -1;
    for (let a = 0; a < n * n; a++) for (const b of [a + 1, a + n]) {
      if (b >= n * n || (b === a + 1 && b % n === 0)) continue;
      const t = labels.slice(); [t[a], t[b]] = [t[b], t[a]];
      const cl = new Set([...runs(t, a), ...runs(t, b)]); if (!cl.size) continue;
      const sc = [...cl].filter((i) => stat[i]).length * 3 + cl.size; if (sc > bs) { bs = sc; best = [a, b]; }
    }
    if (!best) { await page.waitForTimeout(250); continue; }
    await page.locator('.m3-tile').nth(best[0]).click(); await page.locator('.m3-tile').nth(best[1]).click();
    await page.waitForTimeout(600);
  }
  if (!cardAt) { await page.locator('.clue-card').waitFor({ timeout: 6000 }).catch(() => {}); cardAt = Date.now(); }
  const imgOk = await page.evaluate(() => { const i = document.querySelector('.m3-reveal img'); return !!i && i.naturalWidth > 0; });
  ok('match-3 level 7 is cleared by an aiming player in under 60 swaps', clearedAt > 0, `${Math.round((Date.now() - t0) / 1000)}s`);
  ok('match-3 shows the revealed picture and holds it for at least 1.5s', imgOk && clearedAt > 0 && cardAt - clearedAt >= 1500, `${cardAt - clearedAt}ms`);
  await page.screenshot({ path: `${SHOTS}/match3-reveal.png` });

  ok('no JS errors in the bug checks', page.errors.length === 0, page.errors.slice(0, 3).join(' | '));
  await page.context().close();
}

// Title screenshot
{
  const page = await newPage();
  await page.goto(FILE);
  await page.screenshot({ path: `${SHOTS}/title.png` });
  await page.context().close();
}

await browser.close();
const failed = results.filter((r) => !r.pass);
console.log(`\n${results.length - failed.length}/${results.length} checks passed.`);
process.exit(failed.length ? 1 : 0);
