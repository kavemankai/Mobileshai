module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st(); const steps = s.steps; console.log('steps', JSON.stringify(steps));
  let n=0, dragged=false;
  for (const [spot, item, kind] of steps){
    s = await c.st();
    const sp = s.spots.find(x=>x.id===spot);
    if (!sp) { console.log('spot not visible', spot); break; }
    if (kind==='keypad'){
      await c.click(sp.x, sp.y); await c.sleep(500); await c.shot('2-keypad');
      for (const ch of s.code){ const r=(await c.rects()).find(r=>r.id==='kp.'+ch); await c.click(r.x+r.w/2,r.y+r.h/2); await c.sleep(120); }
      const ok=(await c.rects()).find(r=>r.id==='kp.✓'); await c.click(ok.x+ok.w/2,ok.y+ok.h/2); await c.sleep(900);
    } else if (item){
      const it = s.items.find(x=>x.id===item);
      if (!dragged){ dragged=true; await c.drag([[it.x,it.y],[(it.x+sp.x)/2,(it.y+sp.y)/2],[sp.x,sp.y]],40); await c.sleep(300); await c.shot('1-drag'); }
      else { await c.click(it.x,it.y); await c.sleep(120); await c.click(sp.x,sp.y); await c.sleep(450); }
    } else { await c.click(sp.x,sp.y); await c.sleep(650); }
    n++;
  }
  await c.sleep(600); await c.shot('3-solved');
  s = await c.st(); console.log('flags', JSON.stringify(s.flags), 'done', s.done);
  await c.sleep(2200); console.log('phase', (await c.state()).phase);
};
