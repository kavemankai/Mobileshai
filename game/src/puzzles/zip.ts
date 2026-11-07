// Zip path: draw one line through the numbered cells in order, filling every open cell.

import { h } from '../core/dom';
import type { PuzzleMount, ZipDef } from '../core/types';

export interface ZipModel {
  rows: number; cols: number;
  open: boolean[];
  /** cell index -> mark order (0-based) */
  markAt: Map<number, number>;
  markCount: number;
  solution: number[];
}

const STEP: Record<string, [number, number]> = { U: [-1, 0], D: [1, 0], L: [0, -1], R: [0, 1] };

export function zipModel(def: ZipDef): ZipModel {
  const { rows, cols } = def;
  let [r, c] = def.start;
  const solution = [r * cols + c];
  for (const m of def.moves) {
    const [dr, dc] = STEP[m];
    r += dr; c += dc;
    if (r < 0 || c < 0 || r >= rows || c >= cols) throw new Error('zip path leaves grid');
    const i = r * cols + c;
    if (solution.includes(i)) throw new Error('zip path revisits a cell');
    solution.push(i);
  }
  const open = Array.from({ length: rows * cols }, (_, i) => solution.includes(i));
  const markAt = new Map<number, number>();
  def.marks.forEach((idx, order) => markAt.set(solution[idx], order));
  if (def.marks[0] !== 0 || def.marks[def.marks.length - 1] !== solution.length - 1) throw new Error('zip marks must start and end the path');
  return { rows, cols, open, markAt, markCount: def.marks.length, solution };
}

export const adjacent = (m: ZipModel, a: number, b: number) => {
  const ar = Math.floor(a / m.cols), ac = a % m.cols, br = Math.floor(b / m.cols), bc = b % m.cols;
  return Math.abs(ar - br) + Math.abs(ac - bc) === 1;
};

/** Can the path be extended into cell `next`? */
export function canExtend(m: ZipModel, path: number[], next: number): boolean {
  if (!m.open[next] || path.includes(next)) return false;
  if (path.length === 0) return m.markAt.get(next) === 0;
  if (!adjacent(m, path[path.length - 1], next)) return false;
  const reached = path.filter((i) => m.markAt.has(i)).length;
  const mk = m.markAt.get(next);
  if (mk !== undefined && mk !== reached) return false;
  // The final number must be the last cell.
  const openCount = m.open.filter(Boolean).length;
  if (mk === m.markCount - 1 && path.length + 1 !== openCount) return false;
  return true;
}

export function zipSolved(m: ZipModel, path: number[]): boolean {
  const openCount = m.open.filter(Boolean).length;
  return path.length === openCount && m.markAt.get(path[path.length - 1]) === m.markCount - 1;
}

/** Counts complete solutions (stops at `limit`). Used by tests to measure how guessable a board is. */
export function countZipSolutions(m: ZipModel, limit = 50, budget = 3_000_000): { count: number; exhausted: boolean } {
  const { rows, cols } = m;
  const total = m.open.filter(Boolean).length;
  const start = [...m.markAt].find(([, k]) => k === 0)![0];
  const seen = new Array(rows * cols).fill(false);
  let count = 0, nodes = 0, exhausted = false;
  const nbrs = (i: number) => {
    const r = Math.floor(i / cols), c = i % cols, out: number[] = [];
    if (r > 0) out.push(i - cols);
    if (r < rows - 1) out.push(i + cols);
    if (c > 0) out.push(i - 1);
    if (c < cols - 1) out.push(i + 1);
    return out.filter((j) => m.open[j]);
  };
  const connected = (head: number, left: number) => {
    // Every unvisited open cell must still be reachable from the head.
    const q = [head], mark = new Set([head]);
    let found = 0;
    while (q.length) {
      const x = q.pop()!;
      for (const y of nbrs(x)) if (!seen[y] && !mark.has(y)) { mark.add(y); found++; q.push(y); }
    }
    return found === left;
  };
  const dfs = (i: number, len: number, reached: number): void => {
    if (count >= limit || exhausted) return;
    if (++nodes > budget) { exhausted = true; return; }
    if (len === total) { if (m.markAt.get(i) === m.markCount - 1) count++; return; }
    if (!connected(i, total - len)) return;
    for (const j of nbrs(i)) {
      if (seen[j]) continue;
      const mk = m.markAt.get(j);
      if (mk !== undefined && mk !== reached) continue;
      if (mk === m.markCount - 1 && len + 1 !== total) continue;
      seen[j] = true;
      dfs(j, len + 1, reached + (mk !== undefined ? 1 : 0));
      seen[j] = false;
    }
  };
  seen[start] = true;
  dfs(start, 1, 1);
  return { count, exhausted };
}

export const mountZip: PuzzleMount<ZipDef> = (def, ctx) => {
  const m = zipModel(def);
  let path: number[] = [];
  let dragging = false;
  let done = false;

  // Equal rows and columns (minmax(0,1fr)) so a numbered cell never grows its row.
  const board = h('div', {
    class: 'zip-board',
    style: { gridTemplateColumns: `repeat(${m.cols}, minmax(0, 1fr))`, gridTemplateRows: `repeat(${m.rows}, minmax(0, 1fr))`, aspectRatio: `${m.cols} / ${m.rows}` },
  });
  const overlay = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  overlay.setAttribute('class', 'zip-line');
  const cells: HTMLElement[] = [];
  for (let i = 0; i < m.rows * m.cols; i++) {
    const r = Math.floor(i / m.cols), c = i % m.cols;
    const mk = m.markAt.get(i);
    const wallLabel = def.wallLabels?.[`${r},${c}`];
    const cell = h('div', {
      class: `zip-cell${m.open[i] ? '' : ' wall'}${mk !== undefined ? ' mark' : ''}`,
      'data-i': i,
      role: m.open[i] ? 'button' : undefined,
      'aria-label': mk !== undefined ? `Number ${mk + 1}${def.markLabels?.[mk] ? ', ' + def.markLabels[mk] : ''}` : m.open[i] ? `Cell ${r + 1}, ${c + 1}` : wallLabel || 'Wall',
    });
    if (mk !== undefined) cell.append(h('span', { class: 'zip-num', text: mk + 1 }));
    cells.push(cell);
    board.append(cell);
  }
  board.append(overlay);

  // The line is drawn from each cell's real position, so it always sits on the cells it covers.
  const draw = () => {
    cells.forEach((el, i) => el.classList.toggle('on', path.includes(i)));
    const w = board.clientWidth, ht = board.clientHeight;
    overlay.setAttribute('viewBox', `0 0 ${w} ${ht}`);
    const centre = (i: number) => `${cells[i].offsetLeft + cells[i].offsetWidth / 2},${cells[i].offsetTop + cells[i].offsetHeight / 2}`;
    const sw = Math.max(6, (cells[0]?.offsetWidth ?? 40) * 0.3);
    overlay.innerHTML = path.length > 1 ? `<polyline points="${path.map(centre).join(' ')}" stroke-width="${sw}" />` : '';
    const reached = path.filter((i) => m.markAt.has(i)).length;
    const open = m.open.filter(Boolean).length;
    ctx.status(path.length ? `${path.length} of ${open} squares · next number: ${Math.min(reached + 1, m.markCount)}` : 'Start on 1. Drag, or tap neighbouring squares.');
  };

  // Which cell is under the finger: ask the browser, don't do arithmetic on the board size.
  const cellAt = (e: PointerEvent): number | null => {
    const el = document.elementFromPoint(e.clientX, e.clientY)?.closest<HTMLElement>('.zip-cell');
    return el && board.contains(el) ? Number(el.dataset.i) : null;
  };

  const touch = (i: number, fromDrag: boolean) => {
    if (done) return;
    const at = path.indexOf(i);
    if (at >= 0) {
      if (fromDrag && at === path.length - 2) { path.pop(); ctx.sfx('tap'); }
      else if (!fromDrag) { path = path.slice(0, at + 1); ctx.sfx('tap'); }
      draw();
      return;
    }
    if (canExtend(m, path, i)) {
      path.push(i);
      ctx.sfx(m.markAt.has(i) ? 'click' : 'tap');
      draw();
      if (zipSolved(m, path)) { done = true; board.classList.add('solved'); ctx.sfx('power'); ctx.solved(); }
    } else if (!fromDrag) {
      if (path.length === 0) ctx.status('Start on the square marked 1.');
      else if (m.markAt.has(i)) ctx.status('Numbers have to be reached in order, and the last number ends the line.');
      ctx.sfx('invalid');
    }
  };

  board.addEventListener('pointerdown', (e) => {
    const i = cellAt(e);
    if (i === null) return;
    dragging = true;
    board.setPointerCapture(e.pointerId);
    if (path.length && i === path[path.length - 1]) return;
    touch(i, false);
  });
  board.addEventListener('pointermove', (e) => {
    if (!dragging) return;
    const i = cellAt(e);
    if (i === null || i === path[path.length - 1]) return;
    touch(i, true);
  });
  const end = () => { dragging = false; };
  board.addEventListener('pointerup', end);
  board.addEventListener('pointercancel', end);

  // Labels live in a legend where they're big enough to read, not inside the squares.
  const legend = def.markLabels ? h('ol', { class: 'zip-legend', 'aria-label': 'Numbered squares' }, ...def.markLabels.map((l, k) => h('li', null, h('b', { text: k + 1 }), ` ${l}`))) : null;
  const blocked = def.wallLabels ? [...new Set(Object.values(def.wallLabels))] : [];
  const walls = blocked.length ? h('p', { class: 'zip-walls', text: `Blocked: ${blocked.join(', ').toLowerCase()}` }) : null;

  ctx.root.append(h('div', { class: 'board-frame' }, board, legend, walls));
  draw();
  const ro = typeof ResizeObserver === 'function' ? new ResizeObserver(() => draw()) : null;
  ro?.observe(board);
  return { destroy: () => ro?.disconnect() };
};
