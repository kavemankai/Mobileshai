const bfs = require('./bfs.js');
function solve(tubes, cap){
  const can=(t,a,b)=>a!==b&&t[a].length&&t[b].length<cap&&(!t[b].length||t[b].slice(-1)===t[a].slice(-1));
  const pour=(t,a,b)=>{ const x=t.slice(); const c=x[a].slice(-1); let run=0; for(let i=x[a].length-1;i>=0&&x[a][i]===c;i--) run++; const n=Math.min(run,cap-x[b].length); x[a]=x[a].slice(0,x[a].length-n); x[b]+=c.repeat(n); return x; };
  const fin=t=>t.every(s=>!s.length||(s.length===cap&&[...s].every(ch=>ch===s[0])));
  return bfs(tubes, t=>{ const o=[]; for(let a=0;a<t.length;a++) for(let b=0;b<t.length;b++) if(can(t,a,b)) o.push([[a,b],pour(t,a,b)]); return o; }, fin, t=>t.join('|'));
}
module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st();
  const path = solve(s.tubes.slice(), s.cap);
  console.log('moves', path && path.length);
  let n=0;
  for (const [a,b] of path){
    s = await c.st();
    await c.click(s.pts[a][0], s.pts[a][1]); await c.sleep(180);
    if (n===2) await c.shot('1-selected');
    await c.click(s.pts[b][0], s.pts[b][1]);
    if (n===2){ await c.sleep(330); await c.shot('2-pouring'); }
    for (let w=0; w<40; w++){ await c.sleep(100); if(!(await c.st()).busy) break; }
    n++;
  }
  await c.sleep(400); await c.shot('3-solved');
  s = await c.st(); console.log('tubes', JSON.stringify(s.tubes), 'done', s.done);
  await c.sleep(2600); console.log('phase', (await c.state()).phase);
};
