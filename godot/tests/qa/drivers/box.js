const bfsLevers = (start)=>{ const N=start.length, n=Math.round(Math.sqrt(N)); let best=null;
  const tog=(s,i)=>{ const o=s.slice(); const r=Math.floor(i/n), c=i%n; for(const [dr,dc] of [[0,0],[1,0],[-1,0],[0,1],[0,-1]]){ const rr=r+dr, cc=c+dc; if(rr>=0&&cc>=0&&rr<n&&cc<n) o[rr*n+cc]^=1; } return o; };
  for(let m=0;m<(1<<N);m++){ let s=start, p=[]; for(let i=0;i<N;i++) if(m&(1<<i)){ s=tog(s,i); p.push(i);} if(s.every(Boolean)&&(!best||p.length<best.length)) best=p; } return best; };
module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st(); let last=-1, shots=0;
  for (let guard=0; guard<12 && !s.done; guard++){
    for (let w=0; w<30; w++){ s = await c.st(); if (!s.busy || s.done) break; await c.sleep(150); }
    if (s.done) break;
    const t = s.type, ui = s.ui, stage = s.stage;
    console.log('stage', stage, t);
    if (t==='screws'){ for (const p of ui.pts){ await c.click(p[0],p[1]); await c.sleep(250); } }
    else if (t==='sliders'){ for (let i=0;i<ui.tracks.length;i++){ const p=ui.tracks[i][ui.targets[i]]; await c.drag([[ui.tracks[i][ui.val[i]][0],p[1]],[p[0],p[1]]],30); await c.sleep(250); } }
    else if (t==='dials'){ for (let i=0;i<ui.centers.length;i++){ const L=10, tgt=Number(ui.code[i]); let d=(tgt-ui.val[i]+L)%L; if(d>L/2) d-=L; const [x,y]=ui.centers[i]; if(d) await c.drag([[x,y],[x,y-d*ui.unit/2],[x,y-d*ui.unit]],70); await c.sleep(450); } }
    else if (t==='levers'){ const press=bfsLevers(ui.state); for (const i of press){ await c.click(ui.pts[i][0],ui.pts[i][1]); await c.sleep(220);} }
    else if (t==='press'){ const wrong=(ui.target+1)%ui.pts.length; await c.click(ui.pts[wrong][0],ui.pts[wrong][1]); await c.sleep(400); await c.shot('1-wrong'); await c.click(ui.pts[ui.target][0],ui.pts[ui.target][1]); await c.sleep(300); }
    else if (t==='patch'){ const bad=(ui.pairs[0]+1)%ui.right.length; await c.click(ui.left[0][0],ui.left[0][1]); await c.sleep(150); await c.click(ui.right[bad][0],ui.right[bad][1]); await c.sleep(200); await c.shot('1-spark');
      for (let i=0;i<ui.left.length;i++){ await c.click(ui.left[i][0],ui.left[i][1]); await c.sleep(150); await c.click(ui.right[ui.pairs[i]][0],ui.right[ui.pairs[i]][1]); await c.sleep(450); if(i===1) await c.shot('2-cables'); } }
    else if (t==='tilt'){ for (const d of ui.solution){ const r=(await c.rects()).find(r=>r.id==='tilt.'+d); await c.click(r.x+r.w/2,r.y+r.h/2); for(let w=0;w<30;w++){ await c.sleep(90); if(!(await c.st()).ui.moving) break; } } }
    if (stage===0) await c.shot('mid-'+t);
    for (let w=0; w<40; w++){ await c.sleep(150); const n=await c.st(); if(n.done||(n.stage!==stage&&!n.busy)) break; }
  }
  await c.sleep(600); await c.shot('9-solved');
  s = await c.st(); console.log('done', s.done, 'stage', s.stage);
  await c.sleep(2200); console.log('phase', (await c.state()).phase);
};
