// Tilt maze: tilt (or swipe, or tap an arrow) and the ball rolls until it hits a wall.
// It has to come to rest on the goal. Holes send it back to the start.

import { h } from '../core/dom';
import type { PuzzleCtx, PuzzleMount, TiltDef } from '../core/types';

export type Dir = 'U' | 'D' | 'L' | 'R';
const D: Record<Dir, [number, number]> = { U: [-1, 0], D: [1, 0], L: [0, -1], R: [0, 1] };

export function find(rows: string[], ch: string): [number, number] {
  for (let r = 0; r < rows.length; r++) { const c = rows[r].indexOf(ch); if (c >= 0) return [r, c]; }
  throw new Error(`tilt maze missing ${ch}`);
}

/** Rolls the ball. Returns the path of cells and whether it fell in a hole. */
export function roll(rows: string[], from: [number, number], dir: Dir): { path: [number, number][]; hole: boolean } {
  const [dr, dc] = D[dir];
  let [r, c] = from;
  const path: [number, number][] = [];
  for (;;) {
    const nr = r + dr, nc = c + dc;
    const ch = rows[nr]?.[nc];
    if (ch === undefined || ch === '#') return { path, hole: false };
    r = nr; c = nc; path.push([r, c]);
    if (ch === 'O') return { path, hole: true };
  }
}

/** Shortest tilt sequence from S to rest on G, or null. */
export function tiltPath(rows: string[]): Dir[] | null {
  const s = find(rows, 'S'), g = find(rows, 'G');
  const key = (p: [number, number]) => p.join(',');
  const prev = new Map<string, [string, Dir]>();
  const seen = new Set([key(s)]);
  let frontier: [number, number][] = [s];
  while (frontier.length) {
    const next: [number, number][] = [];
    for (const p of frontier) for (const d of ['U', 'D', 'L', 'R'] as Dir[]) {
      const { path, hole } = roll(rows, p, d);
      if (!path.length || hole) continue;
      const end = path[path.length - 1];
      if (seen.has(key(end))) continue;
      seen.add(key(end)); prev.set(key(end), [key(p), d]); next.push(end);
      if (end[0] === g[0] && end[1] === g[1]) {
        const out: Dir[] = [];
        for (let k = key(end); prev.has(k); k = prev.get(k)![0]) out.unshift(prev.get(k)![1]);
        return out;
      }
    }
    frontier = next;
  }
  return null;
}

/** Shortest number of tilts from S to rest on G, or -1. */
export function tiltSolve(rows: string[]): number {
  const s = find(rows, 'S'), g = find(rows, 'G');
  const key = (p: [number, number]) => p.join(',');
  const seen = new Set([key(s)]);
  let frontier: [number, number][] = [s];
  for (let depth = 1; depth < 60 && frontier.length; depth++) {
    const next: [number, number][] = [];
    for (const p of frontier) for (const d of ['U', 'D', 'L', 'R'] as Dir[]) {
      const { path, hole } = roll(rows, p, d);
      if (!path.length || hole) continue;
      const end = path[path.length - 1];
      if (end[0] === g[0] && end[1] === g[1]) return depth;
      if (!seen.has(key(end))) { seen.add(key(end)); next.push(end); }
    }
    frontier = next;
  }
  return -1;
}

/** Reusable maze widget, also used as a puzzle-box stage. */
export function tiltWidget(rows: string[], ctx: Pick<PuzzleCtx, 'sfx' | 'haptic' | 'status' | 'reducedMotion'>, onWin: () => void): HTMLElement {
  const start = find(rows, 'S'), goal = find(rows, 'G');
  let ball: [number, number] = [...start];
  let moving = false, done = false, moves = 0;
  const R = rows.length, C = rows[0].length;
  const grid = h('div', { class: 'tm-grid', style: { gridTemplateColumns: `repeat(${C}, 1fr)`, aspectRatio: `${C} / ${R}` }, tabindex: 0, 'aria-label': 'Maze. Swipe, use the arrow keys, or the arrow buttons.' });
  for (let r = 0; r < R; r++) for (let c = 0; c < C; c++) {
    const ch = rows[r][c];
    grid.append(h('div', { class: `tm-cell${ch === '#' ? ' wall' : ''}${ch === 'O' ? ' hole' : ''}${ch === 'G' ? ' goal' : ''}` }));
  }
  const ballEl = h('div', { class: 'tm-ball' });
  grid.append(ballEl);
  const place = () => {
    ballEl.style.left = `${(ball[1] / C) * 100}%`;
    ballEl.style.top = `${(ball[0] / R) * 100}%`;
    ballEl.style.width = `${100 / C}%`;
    ballEl.style.height = `${100 / R}%`;
  };

  const tilt = (d: Dir) => {
    if (moving || done) return;
    const { path, hole } = roll(rows, ball, d);
    if (!path.length) { ctx.sfx('tap'); return; }
    moving = true; moves++;
    ctx.sfx('roll');
    const end = path[path.length - 1];
    const ms = ctx.reducedMotion ? 30 : Math.min(420, 70 * path.length);
    ballEl.style.transitionDuration = `${ms}ms`;
    ball = end; place();
    setTimeout(() => {
      moving = false;
      if (hole) { ctx.sfx('invalid'); ctx.status('It dropped through. Back to the start.'); ball = [...start]; ballEl.style.transitionDuration = '0ms'; place(); return; }
      ctx.haptic(6);
      if (ball[0] === goal[0] && ball[1] === goal[1]) { done = true; grid.classList.add('solved'); onWin(); }
      else ctx.status(`Tilts: ${moves}`);
    }, ms + 20);
  };

  let p0: { x: number; y: number } | null = null;
  grid.addEventListener('pointerdown', (e) => { p0 = { x: e.clientX, y: e.clientY }; });
  grid.addEventListener('pointerup', (e) => {
    if (!p0) return;
    const dx = e.clientX - p0.x, dy = e.clientY - p0.y; p0 = null;
    if (Math.hypot(dx, dy) < 16) return;
    tilt(Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? 'R' : 'L') : dy > 0 ? 'D' : 'U');
  });
  grid.addEventListener('keydown', (e) => {
    const k = { ArrowUp: 'U', ArrowDown: 'D', ArrowLeft: 'L', ArrowRight: 'R' }[e.key] as Dir | undefined;
    if (k) { e.preventDefault(); tilt(k); }
  });

  const pad = h('div', { class: 'tm-pad' },
    ...(['U', 'L', 'R', 'D'] as Dir[]).map((d) => h('button', { class: `btn tm-${d}`, 'aria-label': `Tilt ${({ U: 'up', D: 'down', L: 'left', R: 'right' })[d]}`, text: ({ U: '▲', D: '▼', L: '◀', R: '▶' })[d], onclick: () => tilt(d) })));

  // Optional real tilt. iOS needs a permission tap.
  const motion = h('button', { class: 'btn ghost', text: 'Use phone tilt' });
  let armed = true;
  const onOrient = (e: DeviceOrientationEvent) => {
    const b = e.beta ?? 0, g = e.gamma ?? 0;
    const tiltDir: Dir | null = Math.abs(g) > Math.abs(b - 35) ? (g > 18 ? 'R' : g < -18 ? 'L' : null) : (b - 35 > 18 ? 'D' : b - 35 < -18 ? 'U' : null);
    if (!tiltDir) { armed = true; return; }
    if (armed) { armed = false; tilt(tiltDir); }
  };
  motion.addEventListener('click', async () => {
    const DOE = DeviceOrientationEvent as unknown as { requestPermission?: () => Promise<string> };
    try {
      if (DOE.requestPermission && (await DOE.requestPermission()) !== 'granted') { ctx.status('Tilt permission was declined. Swipe instead.'); return; }
      window.addEventListener('deviceorientation', onOrient);
      motion.disabled = true; motion.textContent = 'Tilt on. Hold the phone at a comfortable angle.';
    } catch { ctx.status('Tilt is not available here. Swipe instead.'); }
  });

  const wrap = h('div', { class: 'tm-wrap' }, grid, pad, typeof DeviceOrientationEvent !== 'undefined' ? motion : null);
  (wrap as HTMLElement & { cleanup?: () => void }).cleanup = () => window.removeEventListener('deviceorientation', onOrient);
  requestAnimationFrame(place);
  place();
  return wrap;
}

export const mountTilt: PuzzleMount<TiltDef> = (def, ctx) => {
  const w = tiltWidget(def.rows, ctx, () => { ctx.sfx('solve'); ctx.solved(); });
  ctx.root.append(h('div', { class: 'board-frame' }, h('p', { class: 'board-caption', text: def.caption }), w));
  ctx.status('The ball only stops at a wall. It has to stop on the gold valve.');
  return { destroy: () => (w as HTMLElement & { cleanup?: () => void }).cleanup?.() };
};
