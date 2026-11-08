module.exports = async (c) => {
  const rect = async id => (await c.rects()).find(r=>r.id===id);
  await c.shot('0-start');
  let s = await c.st();
  const chk = await rect('tl.check');
  await c.click(chk.x+chk.w/2, chk.y+chk.h/2); await c.sleep(300);
  await c.shot('1-wrong');
  const visible = (s,id)=>{ const g=s.grips[id]; return g[1]>s.view[0]+25 && g[1]<s.view[1]-25; };
  let drags=0, arrows=0;
  for (let i=0;i<s.solution.length;i++){
    for (let guard=0; guard<60; guard++){
      s = await c.st();
      const want = s.solution[i]; const j = s.order.indexOf(want);
      if (j===i) break;
      const g = s.grips[want];
      const dy = (i-j)*s.step_css;
      if (visible(s,want) && g[1]+dy>s.view[0]+25 && g[1]+dy<s.view[1]-25){
        await c.drag([[g[0],g[1]],[g[0],g[1]+dy/2],[g[0],g[1]+dy]],90); drags++;
        await c.sleep(350);
      } else {
        // out of view: scroll toward it, then use the arrow
        if (!visible(s,want)){ await c.p.mouse.move(g[0]+60, (s.view[0]+s.view[1])/2); await c.p.mouse.wheel(0, g[1]>(s.view[0]+s.view[1])/2?70:-70); await c.sleep(250); continue; }
        const r = await rect('tl.up.'+want); await c.click(r.x+r.w/2, r.y+r.h/2); arrows++; await c.sleep(300);
      }
    }
    if (i===1) await c.shot('2-mid');
  }
  s = await c.st(); console.log('order', s.order.join(''), 'want', s.solution.join(''), 'drags', drags, 'arrows', arrows);
  const k = await rect('tl.check'); await c.click(k.x+k.w/2, k.y+k.h/2); await c.sleep(500);
  await c.shot('3-solved');
  await c.sleep(2500);
  console.log('phase', (await c.state()).phase);
};
