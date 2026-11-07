module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st();
  await c.click(s.miss[0], s.miss[1]); await c.sleep(200); await c.shot('1-miss');
  let i=0;
  for (const sp of s.spots){
    const st = await c.st();
    await c.click(sp.x, sp.y); await c.sleep(130);
    if (i===1) { await c.sleep(150); await c.shot('2-flying'); }
    i++;
  }
  await c.sleep(900); await c.shot('3-solved');
  s = await c.st(); console.log('got', JSON.stringify(s.got), 'done', s.done);
  await c.sleep(2400); console.log('phase', (await c.state()).phase);
};
