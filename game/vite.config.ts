import { readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { join, relative } from 'node:path';
import { defineConfig, type Plugin } from 'vite';
import { viteSingleFile } from 'vite-plugin-singlefile';

// Writes the list of every built file into dist/sw.js so the PWA works fully offline after one visit.
function precacheList(): Plugin {
  return {
    name: 'precache-list',
    apply: 'build',
    closeBundle() {
      const out = 'dist';
      const files: string[] = [];
      const walk = (d: string) => readdirSync(d).forEach((f) => { const p = join(d, f); if (statSync(p).isDirectory()) walk(p); else files.push(relative(out, p).split('\\').join('/')); });
      walk(out);
      const list = files.filter((f) => f !== 'sw.js').map((f) => './' + f);
      const sw = join(out, 'sw.js');
      const src = readFileSync(sw, 'utf8');
      if (!src.includes('self.__PRECACHE = [];')) throw new Error('sw.js precache placeholder missing');
      writeFileSync(sw, src.replace('self.__PRECACHE = [];', `self.__PRECACHE = ${JSON.stringify(list)};`));
    },
  };
}

// `vite build` makes the installable PWA in dist/.
// `vite build --mode single` makes one self-contained HTML file in dist-single/ for sharing offline.
export default defineConfig(({ mode }) => {
  const single = mode === 'single';
  return {
    base: './',
    plugins: single ? [viteSingleFile()] : [precacheList()],
    publicDir: single ? false : 'public',
    build: {
      outDir: single ? 'dist-single' : 'dist',
      assetsInlineLimit: single ? 100_000_000 : 4096,
      target: 'es2020',
    },
    define: { __SINGLE_FILE__: JSON.stringify(single) },
    test: { include: ['tests/**/*.test.ts'], testTimeout: 60000 },
  };
});
