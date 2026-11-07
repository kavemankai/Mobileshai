// Shared types for story data, puzzle definitions and the puzzle module contract.

export type SceneKey =
  | 'exterior' | 'reception' | 'security' | 'service' | 'corridor17' | 'room17'
  | 'yard' | 'records' | 'laundry';

export type Speaker = string; // e.g. 'NARRATOR', 'YOU', 'OWEN · PHONE'
export type Line = [Speaker, string];

export interface Clue { title: string; text: string }

export type Edge = 'N' | 'E' | 'S' | 'W';

// ---------- puzzle definitions ----------

export interface ZipDef {
  kind: 'zip';
  rows: number; cols: number;
  start: [number, number];
  /** Solution path as moves from start: U D L R. Cells not on the path are walls. */
  moves: string;
  /** Indices along the solution path that carry numbers. Must include 0 and the last index. */
  marks: number[];
  /** Optional labels for numbered cells (by mark order) or wall cells ("r,c"). */
  markLabels?: string[];
  wallLabels?: Record<string, string>;
}

export interface HiddenTarget { id: string; label: string; glyph: string; x: number; y: number; count?: number }
export interface HiddenDef {
  kind: 'hidden';
  scene: SceneKey;
  targets: HiddenTarget[];
  /** Extra positions for repeated targets (same id), as [x, y] pairs in percent. */
  extra?: Record<string, [number, number][]>;
  clutterGlyphs: string[];
  clutter: number;
}

export interface PanelView { name: string; exits: [Edge, Edge]; caption: string }
export interface PanelDef { id: string; label: string; views: [PanelView, PanelView] }
export interface PanelsDef {
  kind: 'panels';
  rows: number; cols: number;
  panels: PanelDef[];
  start: { slot: number; edge: Edge };
  end: { slot: number; edge: Edge };
  /** Panel ids in the order the path must pass through them (the story order). */
  order: string[];
}

export interface Match3Def {
  kind: 'match3';
  size: number;
  colors: number;
  /** Rows of '#' (covered by static) and '.' (clear). */
  mask: string[];
  reveal: { title: string; lines: string[] };
}

export interface TimelineCard { id: string; title: string; detail: string }
export interface TimelineDef { kind: 'timeline'; cards: TimelineCard[]; order: string[]; prompt: string }

export type LogicRule = { t: 'same' | 'diff'; a: [number, number]; b: [number, number] };
export interface LogicDef {
  kind: 'logic';
  categories: { name: string; items: string[] }[]; // exactly 3 categories of equal size
  clues: { text: string; rule?: LogicRule }[];
  /** solution[i] = [index in category 1, index in category 2] for item i of category 0. */
  solution: [number, number][];
  accuse?: { prompt: string; answer: number; wrong: Record<number, string> };
}

export interface CryptexDef { kind: 'cryptex'; word: string; rings: string[]; clue: string }

export interface GoodsDef {
  kind: 'goods';
  capacity: number;
  racks: string[][]; // '' = empty slot
  types: Record<string, { label: string; color: string }>;
  leftover: string;
}

export interface WaterDef {
  kind: 'water';
  capacity: number;
  tubes: string[]; // bottom -> top
  colors: Record<string, { label: string; color: string }>;
}

export interface BlockFitDef { kind: 'blockfit'; solution: string[]; caption: string }

export interface TiltDef { kind: 'tilt'; rows: string[]; caption: string }

export type BoxStage =
  | { type: 'screws'; count: number; plate: string; note: string }
  | { type: 'sliders'; targets: number[]; clue: string; note: string }
  | { type: 'dials'; code: string; clue: string; note: string }
  | { type: 'levers'; start: number[]; clue: string; note: string }
  | { type: 'press'; count: number; target: number; clue: string; note: string }
  | { type: 'patch'; left: string[]; right: string[]; pairs: number[]; clue: string; note: string }
  | { type: 'tilt'; rows: string[]; clue: string; note: string };
export interface BoxDef { kind: 'box'; name: string; stages: BoxStage[] }

export interface Hotspot {
  id: string;
  label: string;
  icon: string;
  x: number; y: number; w: number; h: number; // percent of the scene
  text: string;
  doneText?: string;
  visibleIf?: string;
  hiddenIf?: string;
  needs?: string;
  needsText?: string;
  consumes?: boolean;
  gives?: string;
  sets?: string;
  keypad?: boolean;
}
export interface RoomDef {
  kind: 'room';
  scene: SceneKey;
  items: Record<string, { label: string; icon: string }>;
  hotspots: Hotspot[];
  goal: string;
  keypad?: { code: string; sets: string; label: string };
}

export type PuzzleDef =
  | ZipDef | HiddenDef | PanelsDef | Match3Def | TimelineDef | LogicDef | CryptexDef
  | GoodsDef | WaterDef | BlockFitDef | TiltDef | BoxDef | RoomDef;
export type PuzzleKind = PuzzleDef['kind'];

export interface Level {
  ch: number;
  title: string;
  scene: SceneKey;
  task: string;
  intro: Line[];
  reveal: Line[];
  clue: Clue;
  hints: [string, string];
  puzzle: PuzzleDef;
}

export interface Chapter { name: string; subtitle: string }

// ---------- puzzle module contract ----------

export type SfxName =
  | 'tap' | 'pick' | 'place' | 'invalid' | 'solve' | 'clue' | 'power' | 'door' | 'paper' | 'metal'
  | 'click' | 'static' | 'phone' | 'pour' | 'clear' | 'roll' | 'ratchet' | 'latch' | 'chapter'
  | 'swap' | 'found' | 'combo';

export interface PuzzleCtx {
  root: HTMLElement;
  seed: number;
  reducedMotion: boolean;
  sfx(name: SfxName): void;
  haptic(ms?: number): void;
  /** Short feedback line under the board. */
  status(msg: string): void;
  /** Call exactly once when the puzzle is solved. */
  solved(): void;
  clues: Clue[];
}

export interface PuzzleInstance { destroy?(): void }
export type PuzzleMount<D extends PuzzleDef> = (def: D, ctx: PuzzleCtx) => PuzzleInstance;
