module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st();
  const n = s.n, sol = s.solution;
  // cross out a run of squares by dragging along row 0, away from its watcher
  const free = [...Array(n).keys()].filter(x => Math.abs(x - sol[0]) > 1);
  if (free.length >= 2) {
    const a = s.cells[0][free[0]], b = s.cells[0][free[free.length - 1]];
    await c.drag([[a[0], a[1]], [(a[0] + b[0]) / 2, a[1]], [b[0], b[1]]], 40);
    await c.sleep(200);
  }
  // one deliberate clash: two watchers in the same row, then take it back
  const wrong = (sol[1] + 2) % n;
  await c.click(s.cells[1][wrong][0], s.cells[1][wrong][1]); await c.click(s.cells[1][wrong][0], s.cells[1][wrong][1]);
  await c.click(s.cells[1][sol[1]][0], s.cells[1][sol[1]][1]); await c.click(s.cells[1][sol[1]][0], s.cells[1][sol[1]][1]);
  await c.sleep(300); await c.shot('1-clash');
  await c.click(s.cells[1][wrong][0], s.cells[1][wrong][1]);   // watcher -> empty
  s = await c.st();
  for (let r = 0; r < n; r++) {
    for (let k = 0; k < 3 && (await c.st()).marks[r][sol[r]] !== 2; k++) {
      const p = s.cells[r][sol[r]]; await c.click(p[0], p[1]);
    }
    if (r === 2) await c.shot('2-mid');
  }
  await c.sleep(600); await c.shot('3-solved');
  s = await c.st(); console.log('marks ok', s.done);
};
