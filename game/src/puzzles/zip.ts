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

export const mountZip: PuzzleMount<ZipDef> = (def, ctx) => {
  const m = zipModel(def);
  let path: number[] = [];
  let dragging = false;
  let done = false;

  const board = h('div', { class: 'zip-board', style: { gridTemplateColumns: `repeat(${m.cols}, 1fr)`, aspectRatio: `${m.cols} / ${m.rows}` } });
  const overlay = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  overlay.setAttribute('class', 'zip-line');
  overlay.setAttribute('viewBox', `0 0 ${m.cols * 10} ${m.rows * 10}`);
  overlay.setAttribute('preserveAspectRatio', 'none');
  const cells: HTMLElement[] = [];
  for (let i = 0; i < m.rows * m.cols; i++) {
    const r = Math.floor(i / m.cols), c = i % m.cols;
    const mk = m.markAt.get(i);
    const wallLabel = def.wallLabels?.[`${r},${c}`];
    const cell = h('div', {
      class: `zip-cell${m.open[i] ? '' : ' wall'}${mk !== undefined ? ' mark' : ''}`,
      role: m.open[i] ? 'button' : undefined,
      'aria-label': mk !== undefined ? `Number ${mk + 1}${def.markLabels?.[mk] ? ', ' + def.markLabels[mk] : ''}` : m.open[i] ? `Cell ${r + 1}, ${c + 1}` : wallLabel || 'Wall',
    });
    if (mk !== undefined) {
      cell.append(h('span', { class: 'zip-num', text: mk + 1 }));
      if (def.markLabels?.[mk]) cell.append(h('span', { class: 'zip-label', text: def.markLabels[mk] }));
    } else if (wallLabel) cell.append(h('span', { class: 'zip-label wall-label', text: wallLabel }));
    cells.push(cell);
    board.append(cell);
  }
  board.append(overlay);

  const draw = () => {
    cells.forEach((el, i) => el.classList.toggle('on', path.includes(i)));
    const pts = path.map((i) => `${(i % m.cols) * 10 + 5},${Math.floor(i / m.cols) * 10 + 5}`).join(' ');
    overlay.innerHTML = path.length > 1 ? `<polyline points="${pts}" />` : '';
    const reached = path.filter((i) => m.markAt.has(i)).length;
    const open = m.open.filter(Boolean).length;
    ctx.status(path.length ? `${path.length} of ${open} cells · next number: ${Math.min(reached + 1, m.markCount)}` : 'Start on 1. Drag, or tap neighbouring cells.');
  };

  const cellAt = (e: PointerEvent): number | null => {
    const rect = board.getBoundingClientRect();
    const c = Math.floor(((e.clientX - rect.left) / rect.width) * m.cols);
    const r = Math.floor(((e.clientY - rect.top) / rect.height) * m.rows);
    if (r < 0 || c < 0 || r >= m.rows || c >= m.cols) return null;
    return r * m.cols + c;
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
      if (path.length === 0) ctx.status('Start on the cell marked 1.');
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

  ctx.root.append(h('div', { class: 'board-frame' }, board));
  draw();
  return {};
};
