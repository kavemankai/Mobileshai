const bfsLevers = (start)=>{ const N=start.length, n=Math.round(Math.sqrt(N)); let best=null;
  const tog=(s,i)=>{ const o=s.slice(); const r=Math.floor(i/n), c=i%n; for(const [dr,dc] of [[0,0],[1,0],[-1,0],[0,1],[0,-1]]){ const rr=r+dr, cc=c+dc; if(rr>=0&&cc>=0&&rr<n&&cc<n) o[rr*n+cc]^=1; } return o; };
  for(let m=0;m<(1<<N);m++){ let s=start, p=[]; for(let i=0;i<N;i++) if(m&(1<<i)){ s=tog(s,i); p.push(i);} if(s.every(Boolean)&&(!best||p.length<best.length)) best=p; } return best; };
const bfs = require('./bfs.js');
const mod = (a,n)=>((a%n)+n)%n;
module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st(); let last=-1, shots=0;
  for (let guard=0; guard<12 && !s.done; guard++){
    for (let w=0; w<30; w++){ s = await c.st(); if (!s.busy || s.done) break; await c.sleep(150); }
    if (s.done) break;
    const t = s.type, ui = s.ui, stage = s.stage;
    console.log('stage', stage, t);
    if (t==='screws'){
      for (let num=1; num<=ui.screws.length; num++){
        const cur=(await c.st()).ui; const sc=cur.screws.find(x=>x.num===num); if(!sc||sc.gone) continue;
        const b=cur.bits[sc.head]; await c.click(b[0],b[1]); await c.sleep(120);
        const [cx,cy]=sc.pt, r=18, pts=[];
        for (let a=0;a<=1.8*Math.PI*2;a+=0.35) pts.push([cx+r*Math.cos(a), cy+r*Math.sin(a)]);
        if (num===1){ await c.click(cur.bits[(sc.head+1)%4][0],cur.bits[(sc.head+1)%4][1]); await c.click(cx,cy); await c.sleep(200); await c.shot('1-wrongbit'); await c.click(b[0],b[1]); await c.sleep(120); }
        await c.drag(pts,12); await c.sleep(700);
      } }
    else if (t==='sliders'){
      const n=ui.targets.length;
      const path=bfs(ui.val, s=>{ const out=[]; for(let i=0;i<n;i++) for(let k=0;k<5;k++){ if(k===s[i]) continue; const o=s.slice(); const d=k-s[i]; o[i]=k; o[(i+1)%n]=mod(s[(i+1)%n]-d,5); out.push([[i,k],o]); } return out; }, s=>s.every((v,i)=>v===ui.targets[i]), s=>s.join(','));
      console.log('slider moves', JSON.stringify(path));
      for (const [i,k] of path){ const cur=(await c.st()).ui; const a=cur.tracks[i][cur.val[i]], b=cur.tracks[i][k]; await c.drag([[a[0],a[1]],[(a[0]+b[0])/2,a[1]],[b[0],b[1]]],40); await c.sleep(450); }
    }
    else if (t==='dials'){
      const n=ui.centers.length, goal=ui.code.split('').map(Number);
      const moves=[]; for(let d=-5; d<=4; d++) if(d) moves.push(d);
      const path=bfs(ui.val, s=>{ const out=[]; for(let i=0;i<n;i++) for(const d of moves){ const o=s.slice(); o[i]=mod(s[i]+d,10); o[(i+1)%n]=mod(s[(i+1)%n]-d,10); out.push([[i,d],o]); } return out; }, s=>s.every((v,i)=>v===goal[i]), s=>s.join(','));
      console.log('dial moves', JSON.stringify(path));
      for (const [i,d] of path){ const cur=(await c.st()).ui; const [x,y]=cur.centers[i]; await c.drag([[x,y],[x,y-d*cur.unit/2],[x,y-d*cur.unit]],70); await c.sleep(900); }
    }
    else if (t==='levers'){ const press=bfsLevers(ui.state); for (const i of press){ await c.click(ui.pts[i][0],ui.pts[i][1]); await c.sleep(220);} }
    else if (t==='press'){
      const hold=async (p,ms)=>{ await c.p.mouse.move(p[0],p[1]); await c.p.mouse.down(); await c.sleep(ms); await c.p.mouse.up(); };
      const wrong=(ui.target+1)%ui.pts.length; await hold(ui.pts[wrong],300); await c.sleep(300); await c.shot('1-wrong');
      await hold(ui.pts[ui.target],1200); }
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
