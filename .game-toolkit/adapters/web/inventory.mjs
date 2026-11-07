import fs from 'node:fs';
import path from 'node:path';
import { inside, json, print, repoOption, repoRoot, run } from '../../scripts/lib.mjs';

run(({ repo, manifest, map }) => {
  const root = repoRoot(repo);
  const data = json(inside(root, manifest));
  // Adapt an existing manifest with a dotted collection selector and an explicit path field.
  const [selector, field] = map.split(':');
  const entries = selector ? selector.split('.').reduce((value, key) => value?.[key], data) : data;
  if (!entries || typeof entries !== 'object' || !field) throw Error('Expected --map collection:pathField');
  const items = Object.entries(entries).map(([id, value]) => {
    const relative = field === '.' ? value : value?.[field];
    if (typeof relative !== 'string') return { id, status: 'UNMAPPED' };
    const base = path.posix.dirname(manifest);
    const file = inside(root, (base === '.' ? '' : base + '/') + relative);
    const stat = fs.lstatSync(file, { throwIfNoEntry: false });
    return { id, path: relative, bytes: stat?.isFile() ? stat.size : null, status: stat?.isFile() ? 'PRESENT' : 'MISSING' };
  });
  print(items);
  if (!items.length || items.some(item => item.status !== 'PRESENT')) process.exitCode = 1;
}, { ...repoOption, manifest: { type: 'string', default: 'asset-manifest.json' },
  map: { type: 'string', default: 'assets:sourceFile' } });
