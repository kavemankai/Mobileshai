module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st();
  const wait = async () => { for (let w = 0; w < 40; w++) { await c.sleep(100); const t = await c.st(); if (!t.busy) return t; } return c.st(); };
  // one move, then undo it
  let k = s.next; await c.click(s.pts[k][0], s.pts[k][1]); s = await wait();
  const u = (await c.rects()).find(r => r.id === 'screws.undo'); await c.click(u.x + u.w / 2, u.y + u.h / 2); await c.sleep(300);
  s = await c.st();
  let moves = 0;
  while (!s.done && moves < 60) {
    k = s.next; if (k < 0) { console.log('no move'); break; }
    await c.click(s.pts[k][0], s.pts[k][1]);
    if (moves === 3) { await c.sleep(150); await c.shot('1-flying'); }
    s = await wait(); moves++;
    if (moves === 8) await c.shot('2-mid');
  }
  await c.sleep(600); await c.shot('3-solved');
  console.log('screws moves', moves, 'done', (await c.st()).done);
};
