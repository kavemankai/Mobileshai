module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st();
  const wait = async () => { for (let w = 0; w < 40; w++) { await c.sleep(80); const t = await c.st(); if (!t.busy) return t; } return c.st(); };
  const V = { U: [0, -1], D: [0, 1], L: [-1, 0], R: [1, 0] };
  let moves = 0;
  while (!s.done && moves < 40) {
    const path = s.solution; if (!path.length) { console.log('no path'); break; }
    const [i, d] = path[0]; const ctr = s.centers[i]; const v = V[d]; const k = s.cell_css;
    const pts = [[ctr[0], ctr[1]]]; for (let st = 1; st <= 10; st++) pts.push([ctr[0] + v[0] * k * 0.6 * st, ctr[1] + v[1] * k * 0.6 * st]);
    await c.drag(pts, 20);
    if (moves === 2) await c.shot('1-mid');
    s = await wait(); moves++;
  }
  await c.sleep(500); await c.shot('2-solved');
  console.log('jam moves', moves, 'done', (await c.st()).done);
};
