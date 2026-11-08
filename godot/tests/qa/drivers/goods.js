function solve(racks, cap, leftover){
  const key = r=>r.map(x=>x.slice().sort().join('')).sort().join('|'); const seen=new Set(); const path=[];
  const fin = r=>{const l=r.flat(); return l.length===1&&l[0]===leftover;};
  const dfs=(r)=>{ if(fin(r)) return true; if(path.length>40) return false; const k=key(r); if(seen.has(k)) return false; seen.add(k);
    for(let a=0;a<r.length;a++) for(let s=0;s<r[a].length;s++) for(let b=0;b<r.length;b++){ if(a===b||r[b].length>=cap) continue;
      const n=r.map(x=>x.slice()); const [c]=n[a].splice(s,1); n[b].push(c); if(n[b].length===cap&&n[b].every(x=>x===n[b][0])) n[b]=[];
      path.push([a,s,b]); if(dfs(n)) return true; path.pop(); } return false; };
  return dfs(racks)?path:null;
}
module.exports = async (c) => {
  await c.shot('0-start');
  let s = await c.st();
  const path = solve(s.racks.map(r=>r.slice()), s.capacity, s.leftover);
  console.log('moves', path && path.length);
  let n=0;
  for (const [a,sl,b] of path){
    s = await c.st();
    const card = s.pts[a].cards[sl];
    await c.click(card[1],card[2]); await c.sleep(120);
    if (n===3) await c.shot('1-selected');
    await c.click(s.pts[b].c[0], s.pts[b].c[1]);
    for (let w=0; w<30; w++){ await c.sleep(100); if(!(await c.st()).busy) break; }
    n++;
    if (n===6) await c.shot('2-mid');
  }
  await c.sleep(300); await c.shot('3-solved');
  s = await c.st(); console.log('racks', JSON.stringify(s.racks), 'done', s.done);
  await c.sleep(2400); console.log('phase', (await c.state()).phase);
};
