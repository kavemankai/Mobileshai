module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st();
  const tap = async (g,r,cc)=>{
    for (let k=0;k<6;k++){ const st=await c.st(); const e = st.cells[g].find(q=>q[0]===r&&q[1]===cc);
      if (e[3]>Math.max(st.view[0],0)+14 && e[3]<Math.min(st.view[1],c.H)-14){ await c.click(e[2],e[3]); await c.sleep(150); return; }
      const lo=Math.max(st.view[0],0), hi=Math.min(st.view[1],c.H), mid=(lo+hi)/2; await c.p.mouse.move(st.view_x, Math.min(Math.max(mid,60),c.H-60)); await c.p.mouse.wheel(0, e[3]>mid?80:-80); await c.sleep(200); }
    throw new Error('cell not reachable'); };
  // one deliberate cross first
  await tap('AB',0,1); await c.shot('1-cross');
  for (let a=0;a<s.solution.length;a++){
    for (const [g,j] of [['AB',s.solution[a][0]],['AC',s.solution[a][1]]]){
      const m = (await c.st()).marks[g][a][j];
      for (let k=0;k<(2-m+3)%3;k++) await tap(g,a,j);
    }
    if (a===0) { await c.sleep(600); await c.shot('2-tick'); }
  }
  await c.sleep(1500);
  s = await c.st(); console.log('grid_done', s.grid_done, 'accuse', s.accuse);
  await c.shot('3-grid');
  if (s.accuse){
    await c.sleep(600); const wrong = (await c.rects()).find(r=>r.id==='logic.accuse.0'); await c.click(wrong.x+wrong.w/2, wrong.y+wrong.h/2); await c.sleep(300); await c.shot('4-wrong');
    const ok = (await c.rects()).find(r=>r.id==='logic.accuse.2'); await c.click(ok.x+ok.w/2, ok.y+ok.h/2);
  }
  await c.sleep(2800);
  console.log('phase', (await c.state()).phase);
};
