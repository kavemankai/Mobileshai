module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st();
  const wait = async () => { for (let w = 0; w < 40; w++) { await c.sleep(80); const t = await c.st(); if (!t.busy) return t; } return c.st(); };
  // one blocked tap first
  const blocked = [...Array(s.count).keys()].find(i => !s.free.includes(i));
  if (blocked !== undefined) { await c.click(s.pts[blocked][0], s.pts[blocked][1]); await c.sleep(150); await c.shot('1-bump'); s = await wait(); }
  let moves = 0;
  while (!s.done && moves < 60) {
    if (!s.free.length) { console.log('stuck'); break; }
    const i = s.free[0]; await c.click(s.pts[i][0], s.pts[i][1]);
    if (moves === 2) { await c.sleep(120); await c.shot('2-sliding'); }
    s = await wait(); moves++;
  }
  await c.sleep(500); await c.shot('3-solved');
  console.log('arrows moves', moves, 'done', (await c.st()).done);
};
