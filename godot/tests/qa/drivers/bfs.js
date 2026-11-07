module.exports = function bfs(start, next, goal, key, limit = 400000) {
  const seen = new Map([[key(start), null]]); const q = [start]; const meta = new Map([[key(start), start]]);
  for (let h = 0; h < q.length && seen.size < limit; h++) {
    const s = q[h]; const ks = key(s);
    if (goal(s)) { const path = []; let k = ks; while (seen.get(k)) { const [pk, mv] = seen.get(k); path.push(mv); k = pk; } return path.reverse(); }
    for (const [mv, n] of next(s)) { const kn = key(n); if (!seen.has(kn)) { seen.set(kn, [ks, mv]); q.push(n); } }
  }
  return null;
};
module.exports.dfs = function dfs(start, next, goal, key, limit = 600000) {
  const parent = new Map([[key(start), null]]); const st = [start];
  while (st.length && parent.size < limit) {
    const s = st.pop(); const ks = key(s);
    if (goal(s)) { const path = []; let k = ks; while (parent.get(k)) { const [pk, mv] = parent.get(k); path.push(mv); k = pk; } return path.reverse(); }
    for (const [mv, n] of next(s)) { const kn = key(n); if (!parent.has(kn)) { parent.set(kn, [ks, mv]); st.push(n); } }
  }
  return null;
};
