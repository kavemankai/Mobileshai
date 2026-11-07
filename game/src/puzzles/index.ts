import type { PuzzleCtx, PuzzleDef, PuzzleInstance, PuzzleKind, PuzzleMount } from '../core/types';
import { mountBlockFit } from './blockfit';
import { mountBox } from './box';
import { mountCryptex } from './cryptex';
import { mountGoods } from './goods';
import { mountHidden } from './hidden';
import { mountLogic } from './logic';
import { mountMatch3 } from './match3';
import { mountPanels } from './panels';
import { mountRoom } from './room';
import { mountTilt } from './tilt';
import { mountTimeline } from './timeline';
import { mountWater } from './water';
import { mountZip } from './zip';

const REGISTRY: { [K in PuzzleKind]: PuzzleMount<Extract<PuzzleDef, { kind: K }>> } = {
  zip: mountZip,
  hidden: mountHidden,
  panels: mountPanels,
  match3: mountMatch3,
  timeline: mountTimeline,
  logic: mountLogic,
  cryptex: mountCryptex,
  goods: mountGoods,
  water: mountWater,
  blockfit: mountBlockFit,
  tilt: mountTilt,
  box: mountBox,
  room: mountRoom,
};

export const KIND_LABEL: Record<PuzzleKind, string> = {
  zip: 'Path', hidden: 'Search', panels: 'Frames', match3: 'Signal recovery', timeline: 'Timeline',
  logic: 'Deduction', cryptex: 'Cryptex', goods: 'Sort', water: 'Pump tanks', blockfit: 'Reassemble',
  tilt: 'Maze', box: 'Mechanism', room: 'Explore',
};

export function mountPuzzle(def: PuzzleDef, ctx: PuzzleCtx): PuzzleInstance {
  const mount = REGISTRY[def.kind] as PuzzleMount<PuzzleDef>;
  return mount(def, ctx);
}
