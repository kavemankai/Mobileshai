// Block fit: reassemble the shredded page. Pick a strip, rotate it, tap where its marked
// corner should go. Tap a placed strip to take it back.

import { h } from '../core/dom';
import { rng } from '../core/rng';
import type { BlockFitDef, PuzzleMount } from '../core/types';

export type Cells = [number, number][];

export function normalize(cells: Cells): Cells {
  const mr = Math.min(...cells.map((c) => c[0])), mc = Math.min(...cells.map((c) => c[1]));
  return cells.map(([r, c]) => [r - mr, c - mc] as [number, number]).sort((a, b) => a[0] - b[0] || a[1] - b[1]);
}
export const rotate = (cells: Cells): Cells => normalize(cells.map(([r, c]) => [c, -r] as [number, number]));

export function derivePieces(def: BlockFitDef): { board: boolean[][]; pieces: { id: string; cells: Cells }[] } {
  const board = def.solution.map((row) => [...row].map((ch) => ch !== '.'));
  const map = new Map<string, Cells>();
  def.solution.forEach((row, r) => [...row].forEach((ch, c) => { if (ch !== '.') { if (!map.has(ch)) map.set(ch, []); map.get(ch)!.push([r, c]); } }));
  return { board, pieces: [...map].map(([id, cells]) => ({ id, cells: normalize(cells) })) };
}

const HUES = ['#d9c5a4', '#c9b48e', '#e3d4b5', '#bfa982', '#d4c09c', '#cbb997', '#e0cfa9', '#b8a27b', '#d2bd95', '#c4ad86'];

export const mountBlockFit: PuzzleMount<BlockFitDef> = (def, ctx) => {
  const { board, pieces } = derivePieces(def);
  const rand = rng(ctx.seed);
  const R = board.length, C = board[0].length;
  const shape = pieces.map((p) => { let s = p.cells; const k = Math.floor(rand() * 4); for (let i = 0; i < k; i++) s = rotate(s); return s; });
  const placed: ({ r: number; c: number } | null)[] = pieces.map(() => null);
  let sel: number | null = null;
  let done = false;

  const occ = () => {
    const g: (number | null)[][] = board.map((row) => row.map(() => null));
    placed.forEach((p, i) => { if (p) shape[i].forEach(([dr, dc]) => { g[p.r + dr][p.c + dc] = i; }); });
    return g;
  };

  const grid = h('div', { class: 'bf-grid', style: { gridTemplateColumns: `repeat(${C}, 1fr)` } });
  const tray = h('div', { class: 'bf-tray' });
  const rot = h('button', { class: 'btn', text: '⟳ Rotate strip' });

  const mini = (cells: Cells, color: string, active: boolean) => {
    const rows = Math.max(...cells.map((c) => c[0])) + 1, cols = Math.max(...cells.map((c) => c[1])) + 1;
    const el = h('div', { class: 'bf-mini', style: { gridTemplateColumns: `repeat(${cols}, 1fr)`, gridTemplateRows: `repeat(${rows}, 1fr)`, width: `${cols * 18}px` } });
    cells.forEach(([r, c], k) => el.append(h('span', { style: { gridRow: r + 1, gridColumn: c + 1, background: color }, class: k === 0 && active ? 'anchor' : '' })));
    return el;
  };

  const draw = () => {
    const g = occ();
    grid.innerHTML = '';
    for (let r = 0; r < R; r++) for (let c = 0; c < C; c++) {
      const i = g[r][c];
      const cell = h('button', {
        class: `bf-cell${board[r][c] ? '' : ' off'}${i !== null ? ' filled' : ''}`,
        style: i !== null ? { background: HUES[i % HUES.length] } : undefined,
        'aria-label': board[r][c] ? `Row ${r + 1} column ${c + 1}${i !== null ? ', filled' : ', empty'}` : 'Outside the page',
        disabled: board[r][c] ? undefined : true,
      });
      if (i !== null) cell.append(h('span', { class: 'bf-ink' }));
      cell.addEventListener('click', () => tapCell(r, c));
      grid.append(cell);
    }
    tray.innerHTML = '';
    pieces.forEach((_, i) => {
      if (placed[i]) return;
      const b = h('button', { class: `bf-piece${sel === i ? ' sel' : ''}`, 'aria-label': `Strip ${i + 1}, ${shape[i].length} squares` }, mini(shape[i], HUES[i % HUES.length], sel === i));
      b.addEventListener('click', () => { if (done) return; sel = sel === i ? null : i; ctx.sfx('pick'); draw(); });
      tray.append(b);
    });
    rot.disabled = sel === null || done;
    const left = placed.filter((p) => !p).length;
    ctx.status(left ? `${left} strip${left === 1 ? '' : 's'} left. The gold square is the corner you place.` : '');
  };

  const tapCell = (r: number, c: number) => {
    if (done) return;
    const g = occ();
    const at = g[r][c];
    if (at !== null && sel === null) { placed[at] = null; ctx.sfx('paper'); draw(); return; }
    if (sel === null) { ctx.status('Pick a strip from the tray first.'); return; }
    const [ar, ac] = shape[sel][0];
    const or = r - ar, oc = c - ac;
    const fits = shape[sel].every(([dr, dc]) => {
      const rr = or + dr, cc = oc + dc;
      return rr >= 0 && cc >= 0 && rr < R && cc < C && board[rr][cc] && g[rr][cc] === null;
    });
    if (!fits) { ctx.sfx('invalid'); ctx.status("It doesn't fit there."); return; }
    placed[sel] = { r: or, c: oc };
    sel = null; ctx.sfx('place'); ctx.haptic(6);
    draw();
    if (placed.every(Boolean)) { done = true; grid.classList.add('solved'); ctx.sfx('solve'); ctx.solved(); }
  };

  rot.addEventListener('click', () => { if (sel !== null) { shape[sel] = rotate(shape[sel]); ctx.sfx('click'); draw(); } });
  ctx.root.append(h('div', { class: 'board-frame paper' }, h('p', { class: 'board-caption', text: def.caption }), grid, h('div', { class: 'board-actions' }, rot), tray));
  draw();
  return {};
};
