const norm = cells => { const mr=Math.min(...cells.map(c=>c[0])), mc=Math.min(...cells.map(c=>c[1])); return cells.map(([r,c])=>[r-mr,c-mc]).sort((a,b)=>a[0]-b[0]||a[1]-b[1]); };
const rot = cells => norm(cells.map(([r,c])=>[c,-r]));
const eq = (a,b)=>JSON.stringify(a)===JSON.stringify(b);
module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st(); const n = s.pieces.length; let done=0;
  const rects = async id => (await c.rects()).find(r=>r.id===id);
  for (let guard=0; guard<n*3 && done<n; guard++){
    s = await c.st();
    const idx = s.pieces.findIndex(p=>!p.placed); if (idx<0) break;
    const p = s.pieces[idx];
    let shape = p.shape, k=0; while(!eq(shape,p.sol) && k<4){ shape=rot(shape); k++; }
    if (k>0){ // select by tap, then rotate k times
      await c.click(p.anchor_css[0], p.anchor_css[1]); await c.sleep(150);
      const rr = await rects('bf.rotate');
      for (let i=0;i<k;i++){ await c.click(rr.x+rr.w/2, rr.y+rr.h/2); await c.sleep(300); }
      s = await c.st();
    }
    const q = s.pieces[idx];
    const target = [p.sol_origin[0]+p.sol[0][0], p.sol_origin[1]+p.sol[0][1]];
    const t = s.cells[target[0]][target[1]];
    const a = q.anchor_css;
    await c.drag([[a[0],a[1]],[ (a[0]+t[0])/2, (a[1]+t[1])/2 - 20 ],[t[0],t[1]+34]],25);
    await c.sleep(450);
    if (done===2) await c.shot('1-mid');
    done = (await c.st()).pieces.filter(p=>p.placed).length;
  }
  await c.sleep(500); await c.shot('2-solved');
  s = await c.st(); console.log('placed', s.pieces.filter(p=>p.placed).length, 'of', n, 'done', s.done);
  await c.sleep(2200); console.log('phase', (await c.state()).phase);
};
