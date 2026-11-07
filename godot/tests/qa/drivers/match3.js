module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st(); let moves=0;
  while (s.left>0 && moves<80){
    if (!s.legal.length) { await c.sleep(500); s = await c.st(); continue; }
    const [a,b] = s.legal[Math.floor(Math.random()*s.legal.length)]; const pa=s.centers[a], pb=s.centers[b];
    await c.drag([[pa[0],pa[1]],[ (pa[0]+pb[0])/2, (pa[1]+pb[1])/2 ],[pb[0],pb[1]]], 30);
    if (moves===2) { await c.sleep(160); await c.shot('1-matching'); }
    for (let w=0; w<60; w++){ await c.sleep(120); s = await c.st(); if(!s.busy) break; }
    moves++;
    if (moves===8) await c.shot('2-mid');
  }
  console.log('moves', moves, 'left', s.left, 'done', s.done);
  await c.sleep(1200); await c.shot('3-solved');
  await c.sleep(3200); console.log('phase', (await c.state()).phase);
};
