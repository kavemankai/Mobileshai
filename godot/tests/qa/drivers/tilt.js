module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st(); const sol = s.solution; console.log('solution', sol.join(''));
  const [cx,cy]=s.center, k=s.cell_css*2;
  const vec={U:[0,-k],D:[0,k],L:[-k,0],R:[k,0]};
  let i=0;
  for (const d of sol){
    if (i%3===0) await c.drag([[cx,cy],[cx+vec[d][0]/2,cy+vec[d][1]/2],[cx+vec[d][0],cy+vec[d][1]]],20);   // swipe
    else if (i%3===1) { const r=(await c.rects()).find(r=>r.id==='tilt.'+d); await c.click(r.x+r.w/2,r.y+r.h/2); }  // pad button
    else await c.p.keyboard.press({U:'ArrowUp',D:'ArrowDown',L:'ArrowLeft',R:'ArrowRight'}[d]);                // keyboard
    for (let w=0;w<30;w++){ await c.sleep(80); if(!(await c.st()).moving) break; }
    console.log(i, d, ['swipe','pad','key'][i%3], JSON.stringify((await c.st()).ball));
    if (i===4) await c.shot('1-mid');
    i++;
  }
  await c.sleep(700); await c.shot('2-solved');
  s = await c.st(); console.log('ball', s.ball, 'goal', s.goal, 'done', s.done);
  await c.sleep(2200); console.log('phase', (await c.state()).phase);
};
