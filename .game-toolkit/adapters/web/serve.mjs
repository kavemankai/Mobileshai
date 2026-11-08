import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { inside, repoRoot, run } from '../../scripts/lib.mjs';

const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.css': 'text/css', '.json': 'application/json', '.webmanifest': 'application/manifest+json',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.webp': 'image/webp', '.svg': 'image/svg+xml',
  '.mp3': 'audio/mpeg', '.ogg': 'audio/ogg', '.wav': 'audio/wav', '.woff2': 'font/woff2',
  '.wasm': 'application/wasm' };

run(({ dir, port }) => {
  const root = repoRoot(dir);
  const number = Number(port);
  if (!Number.isInteger(number) || number < 0 || number > 65535) throw Error('Invalid port');
  const server = http.createServer((req, res) => {
    try {
      const name = decodeURIComponent(new URL(req.url, 'http://localhost').pathname).slice(1);
      if (name.split('/').some(part => part.startsWith('.'))) throw Error('Hidden path');
      const file = inside(root, name.endsWith('/') || !name ? name + 'index.html' : name);
      if (!fs.statSync(file).isFile()) throw Error('Expected a file');
      res.setHeader('Content-Type', types[path.extname(file)] ?? 'application/octet-stream');
      if (req.method === 'HEAD') return res.end();
      fs.createReadStream(file).on('error', () => res.destroy()).pipe(res);
    } catch {
      res.writeHead(404).end('Not found');
    }
  });
  server.on('error', error => { console.error(error.message); process.exitCode = 1; });
  server.listen(number, '127.0.0.1', () => console.log('http://127.0.0.1:' + server.address().port));
}, { dir: { type: 'string', default: '.' }, port: { type: 'string', default: '4173' } });
