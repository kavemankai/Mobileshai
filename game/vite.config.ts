import { defineConfig } from 'vite';
import { viteSingleFile } from 'vite-plugin-singlefile';

// `vite build` makes the installable PWA in dist/.
// `vite build --mode single` makes one self-contained HTML file in dist-single/ for sharing offline.
export default defineConfig(({ mode }) => {
  const single = mode === 'single';
  return {
    base: './',
    plugins: single ? [viteSingleFile()] : [],
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
