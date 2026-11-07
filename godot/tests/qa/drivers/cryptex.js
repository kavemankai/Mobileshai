module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st();
  for (let i=0;i<s.rings.length;i++){
    s = await c.st();
    const L = s.rings[i].length, tgt = s.rings[i].indexOf(s.target[i]);
    let d = (tgt - s.pos[i] + L) % L; if (d > L/2) d -= L;
    const [x,y] = s.centers[i];
    if (d) await c.drag([[x,y],[x,y - d*s.unit_css/2],[x,y - d*s.unit_css]],70);
    await c.sleep(500);
    if (i===2) await c.shot('1-mid');
  }
  s = await c.st(); console.log('word', s.word, 'target', s.target, 'done', s.done);
  await c.shot('2-solved');
  await c.sleep(2600);
  console.log('phase', (await c.state()).phase);
};
