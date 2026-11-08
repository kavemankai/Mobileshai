module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st(); const tgt = s.solutions[0]; console.log('target', JSON.stringify(tgt));
  for (let i=0;i<tgt.slots.length;i++){
    s = await c.st();
    const j = s.slots.indexOf(tgt.slots[i]);
    if (j===i) continue;
    await c.click(s.centers[i][0], s.centers[i][1]-10); await c.sleep(150);
    if (i===0) await c.shot('1-selected');
    await c.click(s.centers[j][0], s.centers[j][1]-10); await c.sleep(450);
  }
  s = await c.st();
  for (let pi=0; pi<tgt.views.length; pi++){
    s = await c.st();
    if (s.views[pi]!==tgt.views[pi]){ const slot = s.slots.indexOf(pi); await c.click(s.zooms[slot][0], s.zooms[slot][1]); await c.sleep(500); }
    if (pi===1) await c.shot('2-mid');
  }
  await c.sleep(600); await c.shot('3-solved');
  s = await c.st(); console.log('slots', s.slots.join(''), 'views', s.views.join(''), 'done', s.done);
  await c.sleep(2400); console.log('phase', (await c.state()).phase);
};
