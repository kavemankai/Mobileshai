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
    const smallTargets = await page.evaluate(() => [...document.querySelectorAll('.board-root button')].filter((b) => { const r = b.getBoundingClientRect(); return r.width > 0 && (r.width < 30 || r.height < 30); }).length);
    if (wide || smallTargets > 0) bad.push(`${i + 1}${wide ? ' wide' : ''}${smallTargets ? ` ${smallTargets} small` : ''}`);
  }
  ok('every puzzle fits 360px and has tappable controls', bad.length === 0, bad.join('; '));
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

  // Logic grid, level 11: three ticks in each top block.
  await hook(page, 'jump', 10);
  for (const label of ['Martin Hale and 17', 'Claire Bennett and 12', 'R. Okafor and 04', 'Martin Hale and Prepaid', 'Claire Bennett and Cash', 'R. Okafor and Company']) {
    const cell = page.getByRole('button', { name: new RegExp('^' + label.replace('.', '\\.') + ':') });
    await cell.click(); // ✗
    await page.getByRole('button', { name: new RegExp('^' + label.replace('.', '\\.') + ':') }).click(); // ✓
  }
  ok('logic grid solves by ticking', await solved(page).catch(() => false));

  // Accusation, level 22: wrong answer first.
  await hook(page, 'jump', 21);
  for (const label of ['Owen and Phone', 'Claire and Room 12', 'Daniel and Corridor', 'Owen and Master key', 'Claire and Rental keys', 'Daniel and Encoder']) {
    for (let k = 0; k < 2; k++) await page.getByRole('button', { name: new RegExp('^' + label + ':') }).click();
  }
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

  // Tilt maze, level 24: arrow buttons.
  await hook(page, 'jump', 23);
  for (const d of ['right', 'down', 'left', 'down', 'right', 'down', 'right']) {
    await page.getByRole('button', { name: `Tilt ${d}` }).click();
    await page.waitForTimeout(450);
  }
  ok('tilt maze solves with RDLDRDR', await solved(page).catch(() => false));

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
