#!/usr/bin/env node
// Browser QA for the Godot web build. Drives the real canvas with real mouse and keyboard input through the
// debug bridge (window.__lci, only present with ?debug=1) and checks that every puzzle can be finished
// by legal input. Usage:
//   node godot/tests/qa/run.mjs --level 7 --viewport 390x844
//   node godot/tests/qa/run.mjs --all --viewport 360x640        every level, jumped to directly
//   node godot/tests/qa/run.mjs --full                          title to ending, one continuous run
//   node godot/tests/qa/run.mjs --offline                       reload with the network off after the service worker is up
// Needs: a build in godot/build/web, and `playwright` resolvable (NODE_PATH=$(npm root -g) works).
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const here = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const args = process.argv.slice(2);
const opt = (name, dflt) => { const i = args.indexOf('--' + name); return i < 0 ? dflt : (args[i + 1]?.startsWith('--') || args[i + 1] === undefined ? true : args[i + 1]); };
const webRoot = path.resolve(opt('build', path.resolve(here, '../../build/web')));
const shotDir = path.resolve(opt('shots', path.join(here, 'out')));
fs.mkdirSync(shotDir, { recursive: true });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png', '.json': 'application/json' };
const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://x');
  let p = path.join(webRoot, decodeURIComponent(url.pathname === '/' ? '/index.html' : url.pathname));
  if (!p.startsWith(webRoot) || !fs.existsSync(p)) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'Content-Type': MIME[path.extname(p)] ?? 'application/octet-stream' });
  fs.createReadStream(p).pipe(res);
});
await new Promise((r) => server.listen(0, r));
const base = `http://localhost:${server.address().port}/index.html?debug=1`;

const KINDS = ['zip', 'hidden', 'panels', 'match3', 'timeline', 'logic', 'cryptex', 'goods', 'water', 'blockfit', 'tilt', 'box', 'room'];

async function session(width, height, extra = {}) {
  const browser = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const context = await browser.newContext({ viewport: { width, height }, ...extra });
  const page = await context.newPage();
  const errors = [];
  page.on('console', (m) => { if (/SCRIPT ERROR|^ERROR/.test(m.text()) && !/GPU stall/.test(m.text())) errors.push(m.text().slice(0, 300)); });
  page.on('pageerror', (e) => errors.push('PAGEERR ' + e.message));
  await page.goto(base);
  await page.waitForFunction(() => window.__lci && window.__lci.meta, null, { timeout: 90000 });
  return { browser, context, page, errors, width, height };
}

function helpers(s, tag) {
  const { page, width: W, height: H } = s;
  return {
    p: page, W, H, sleep,
    shot: async (n) => { await sleep(500); await page.screenshot({ path: path.join(shotDir, `${tag}-${W}x${H}-${n}.png`) }); },
    st: () => page.evaluate(() => window.__lci.puzzle()),
    state: () => page.evaluate(() => window.__lci.state()),
    rects: () => page.evaluate(() => window.__lci.rects()),
    drag: async (pts, delay = 60) => { await page.mouse.move(pts[0][0], pts[0][1]); await page.mouse.down(); for (const q of pts.slice(1)) { await page.mouse.move(q[0], q[1], { steps: 4 }); await sleep(delay); } await page.mouse.up(); },
    click: async (x, y) => { await page.mouse.click(x, y); await sleep(120); },
  };
}

async function playLevel(s, level, kind) {
  const c = helpers(s, `L${String(level).padStart(2, '0')}-${kind}`);
  await s.page.evaluate((i) => window.__lci.jump(i), level);
  await sleep(700);
  const driver = (await import(path.join(here, 'drivers', kind + '.js'))).default ?? (await import(path.join(here, 'drivers', kind + '.js')));
  const fn = typeof driver === 'function' ? driver : driver.default;
  await fn(c);
  await sleep(300);
  for (let i = 0; i < 40; i++) { const st = await c.state(); if (st.phase === 'reveal') return true; await sleep(150); }
  return false;
}

function kindOf(levels, i) { return levels[i].kind; }

const [W, H] = String(opt('viewport', '390x844')).split('x').map(Number);
let failed = 0;
try {
  if (opt('offline', false)) {
    const s = await session(W, H);
    await s.page.evaluate(async () => { await navigator.serviceWorker?.ready; });
    await sleep(4000);
    await s.context.setOffline(true);
    await s.page.reload();
    await s.page.waitForFunction(() => window.__lci && window.__lci.meta, null, { timeout: 90000 });
    const m = await s.page.evaluate(() => window.__lci.meta());
    console.log(m.levels === 28 ? 'PASS offline reload' : 'FAIL offline reload', JSON.stringify(m));
    if (m.levels !== 28) failed++;
    await s.browser.close();
  } else if (opt('full', false)) {
    // title to ending in one continuous run, with real saves: no jumps, no sandbox
    const s = await session(W, H);
    const c = helpers(s, 'full');
    const tap = async (id) => { const r = (await c.rects()).find((x) => x.id === id); if (!r) throw new Error('no control ' + id); await c.click(r.x + r.w / 2, r.y + r.h / 2); };
    const kinds = await s.page.evaluate(() => Array.from({ length: window.__lci.meta().levels }, (_, i) => window.__lci.level(i).kind));
    await tap('title.begin'); await sleep(600);
    await tap('name.start'); await sleep(600);
    await s.page.mouse.click(W / 2, H / 2); await sleep(900);          // chapter card
    let t0 = Date.now(), solved = 0, safety = 0;
    while (safety++ < 400) {
      const st = await c.state();
      if (!st) { await sleep(300); continue; }
      if (st.phase === 'end') break;
      if (st.overlay) { await tap('clue.continue').catch(() => {}); await sleep(500); continue; }
      if (st.phase === 'puzzle') {
        const level = st.level, kind = kinds[level];
        const fn = (await import(path.join(here, 'drivers', kind + '.js'))).default;
        await fn(helpers(s, `full-L${level + 1}`));
        solved++;
        for (let i = 0; i < 40; i++) { const x = await c.state(); if (x.overlay || x.phase !== 'puzzle') break; await sleep(150); }
        console.log(`  level ${level + 1} ${kind} solved (${((Date.now() - t0) / 1000).toFixed(0)}s)`);
        continue;
      }
      // story: tap a couple of lines for real, then skip the rest
      if (st.phase === 'intro' || st.phase === 'reveal') { await s.page.mouse.click(W / 2, H / 3); await sleep(250); await s.page.mouse.click(W / 2, H / 3); await sleep(250); }
      await s.page.evaluate(() => window.__lci.finishScene());
      await sleep(350);
    }
    const end = await c.state();
    const bad = s.errors.splice(0);
    const ok = end.phase === 'end' && end.finished && end.clues.length === 28 && solved === 28 && !bad.length;
    console.log(`${ok ? 'PASS' : 'FAIL'} full playthrough ${W}x${H}: phase ${end.phase}, ${end.clues.length} clues, ${solved} puzzles${bad.length ? ', errors: ' + bad[0] : ''}`);
    await c.shot('end');
    if (!ok) failed++;
    await s.browser.close();
  } else if (opt('all', false) || opt('level', null) !== null) {
    const s = await session(W, H);
    const meta = await s.page.evaluate(() => window.__lci.meta());
    const kinds = await s.page.evaluate((n) => Array.from({ length: n }, (_, i) => window.__lci.level(i).kind), meta.levels);
    const wanted = opt('all', false) ? kinds.map((_, i) => i) : [Number(opt('level'))];
    for (const i of wanted) {
      const k = kinds[i];
      const t0 = Date.now();
      let ok = false;
      try { ok = await playLevel(s, i, k); } catch (e) { console.log('  error', e.message.split('\n')[0]); }
      const bad = s.errors.splice(0);
      console.log(`${ok && !bad.length ? 'PASS' : 'FAIL'} level ${i + 1} ${k} ${W}x${H} ${((Date.now() - t0) / 1000).toFixed(0)}s${bad.length ? ' errors: ' + bad[0] : ''}`);
      if (!ok || bad.length) failed++;
      // fresh page each level keeps state independent
      await s.page.reload();
      await s.page.waitForFunction(() => window.__lci && window.__lci.meta, null, { timeout: 90000 });
    }
    await s.browser.close();
  } else {
    console.log('Use --level N, --all, --full or --offline');
  }
} finally {
  server.close();
}
process.exit(failed ? 1 : 0);
