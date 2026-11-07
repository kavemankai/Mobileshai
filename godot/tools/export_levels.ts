// Dumps the story and puzzle data to godot/data/levels.json.
//   cd game && npx vite-node ../godot/tools/export_levels.ts
// The web game's levels.ts stays the source of truth until it is retired; tests keep the JSON in step.

import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { CHAPTERS, LEVELS } from '../../game/src/story/levels';

const out = resolve(__dirname, '../data/levels.json');
writeFileSync(out, JSON.stringify({ chapters: CHAPTERS, levels: LEVELS }, null, 1) + '\n');
console.log(`wrote ${out}: ${CHAPTERS.length} chapters, ${LEVELS.length} levels`);
