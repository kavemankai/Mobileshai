module.exports = async (c) => {
  let s = await c.st();
  const pt = i => s.cells.find(x=>x[0]===i).slice(1);
  await c.shot('0-start');
  const sol = s.solution;
  const half = sol.slice(0, Math.floor(sol.length/2));
  await c.drag(half.map(pt));
  await c.shot('1-mid');
  // back up two cells then go on, as a player would
  await c.drag(sol.map(pt));
  await c.sleep(300);
  await c.shot('2-solved');
  s = await c.st();
  console.log('path len', s.path.length, 'of', sol.length, 'done', s.done);
  await c.sleep(2500);
  console.log('phase after', (await c.state()).phase);
};
