// Logic grid: three categories, classic L-shaped grid. Tap a cell: blank -> ✗ -> ✓.
// Solved when the ✓ marks match the solution; optional accusation afterwards.

import { h } from '../core/dom';
import type { LogicDef, LogicRule, PuzzleMount } from '../core/types';

function permutations(n: number): number[][] {
  if (n === 1) return [[0]];
  const out: number[][] = [];
  for (const p of permutations(n - 1)) for (let i = 0; i <= p.length; i++) out.push([...p.slice(0, i), n - 1, ...p.slice(i)]);
  return out;
}

/** All assignments consistent with the rules. Each is [cat1 index, cat2 index] per cat0 item. */
export function logicSolutions(def: LogicDef): [number, number][][] {
  const n = def.categories[0].items.length;
  const perms = permutations(n);
  const rules = def.clues.map((c) => c.rule).filter(Boolean) as LogicRule[];
  const out: [number, number][][] = [];
  for (const p of perms) for (const q of perms) {
    const owner = (cat: number, item: number) => (cat === 0 ? item : cat === 1 ? p.indexOf(item) : q.indexOf(item));
    if (rules.every((r) => (owner(...r.a) === owner(...r.b)) === (r.t === 'same'))) out.push(p.map((x, i) => [x, q[i]]));
  }
  return out;
}

type Mark = 0 | 1 | 2;

export const mountLogic: PuzzleMount<LogicDef> = (def, ctx) => {
  const [A, B, C] = def.categories;
  const n = A.items.length;
  // grids: 'AB' rows A cols B; 'AC' rows A cols C; 'CB' rows C cols B
  const marks: Record<'AB' | 'AC' | 'CB', Mark[][]> = {
    AB: Array.from({ length: n }, () => Array(n).fill(0)),
    AC: Array.from({ length: n }, () => Array(n).fill(0)),
    CB: Array.from({ length: n }, () => Array(n).fill(0)),
  };
  let gridDone = false, done = false;

  const table = h('div', { class: 'lg-wrap' });
  const accuseBox = h('div', { class: 'lg-accuse' });

  const correct = () => def.solution.every(([b, c], a) =>
    marks.AB[a].every((m, j) => (m === 2) === (j === b)) && marks.AC[a].every((m, j) => (m === 2) === (j === c)));

  const toggle = (g: 'AB' | 'AC' | 'CB', r: number, c: number) => {
    if (gridDone) return;
    const cur = marks[g][r][c];
    const next = ((cur + 1) % 3) as Mark;
    marks[g][r][c] = next;
    if (next === 2) {
      // ✓ crosses out the rest of its row and column in that block.
      for (let k = 0; k < n; k++) {
        if (k !== c && marks[g][r][k] === 0) marks[g][r][k] = 1;
        if (k !== r && marks[g][k][c] === 0) marks[g][k][c] = 1;
      }
    }
    ctx.sfx(next === 2 ? 'click' : 'tap');
    draw();
    if (correct()) {
      gridDone = true;
      table.classList.add('solved');
      if (def.accuse) showAccuse();
      else { done = true; ctx.sfx('solve'); ctx.solved(); }
    }
  };

  const block = (g: 'AB' | 'AC' | 'CB', rows: string[], cols: string[], withColHeads: boolean, withRowHeads: boolean) => {
    const t = h('table', { class: 'lg-block' });
    if (withColHeads) {
      const tr = h('tr');
      if (withRowHeads) tr.append(h('th', { class: 'corner' }));
      cols.forEach((cname) => tr.append(h('th', { class: 'col', scope: 'col' }, h('span', { text: cname }))));
      t.append(tr);
    }
    rows.forEach((rname, r) => {
      const tr = h('tr');
      if (withRowHeads) tr.append(h('th', { class: 'row', scope: 'row', text: rname }));
      cols.forEach((cname, c) => {
        const m = marks[g][r][c];
        tr.append(h('td', null, h('button', {
          class: `lg-cell m${m}`, text: m === 1 ? '✗' : m === 2 ? '✓' : '',
          'aria-label': `${rname} and ${cname}: ${m === 2 ? 'yes' : m === 1 ? 'no' : 'unknown'}`,
          onclick: () => toggle(g, r, c),
        })));
      });
      t.append(tr);
    });
    return t;
  };

  const draw = () => {
    table.innerHTML = '';
    const top = h('div', { class: 'lg-row' }, block('AB', A.items, B.items, true, true), block('AC', A.items, C.items, true, false));
    const bottom = h('div', { class: 'lg-row' }, block('CB', C.items, B.items, false, true));
    table.append(
      h('div', { class: 'lg-legend' }, h('span', { text: `Rows: ${A.name} (top), ${C.name} (bottom)` }), h('span', { text: `Columns: ${B.name}, then ${C.name}` })),
      top, bottom,
    );
  };

  const showAccuse = () => {
    const acc = def.accuse!;
    accuseBox.innerHTML = '';
    accuseBox.append(h('p', { class: 'lg-accuse-q', text: acc.prompt }));
    const btns = h('div', { class: 'board-actions' });
    A.items.forEach((name, i) => btns.append(h('button', {
      class: 'btn', text: name, onclick: () => {
        if (done) return;
        if (i === acc.answer) { done = true; ctx.sfx('solve'); ctx.solved(); }
        else { ctx.sfx('invalid'); ctx.status(acc.wrong[i] ?? 'The evidence doesn\'t support that.'); }
      },
    })));
    accuseBox.append(btns);
    ctx.status('The grid is complete. Now make the call.');
  };

  const clues = h('ol', { class: 'lg-clues' }, ...def.clues.map((c) => h('li', { text: c.text })));
  ctx.root.append(h('div', { class: 'board-frame paper' }, clues, table, accuseBox));
  draw();
  ctx.status('Tap once for ✗, twice for ✓. A ✓ rules out the rest of its row and column.');
  return {};
};
