// Screens and game flow: title -> name -> chapter card -> intro -> puzzle -> evidence -> reveal -> ... -> ending.

import { TITLE_ART } from '../assets/manifest';
import { portraitFor, sceneArt } from '../core/art';
import { audioScene, duckMusic, haptic, mix, sfx, unlockAudio } from '../core/audio';
import { h } from '../core/dom';
import { clearSave, loadSave, newSave, saveSettings, settings, writeSave, type SaveData } from '../core/state';
import type { Clue, Level, PuzzleInstance } from '../core/types';
import { KIND_LABEL, mountPuzzle } from '../puzzles';
import { CHAPTERS, LEVELS } from '../story/levels';

const app = document.querySelector<HTMLElement>('#app')!;

const debug = {
  enabled: new URLSearchParams(location.search).get('debug') === '1' || location.hash === '#debug',
  sandbox: false,
  titleTaps: 0,
};

let game: SaveData | null = null;
let overlay: HTMLElement | null = null;
let puzzle: PuzzleInstance | null = null;
let solvedTimer = 0;

const DEFAULT_NAME = 'Alex';
const fill = (t: string) => t.replaceAll('{name}', game?.name || DEFAULT_NAME);
const cur = (): Level => LEVELS[game!.level];
const levelInChapter = (i: number) => LEVELS.slice(0, i).filter((l) => l.ch === LEVELS[i].ch).length + 1;
const chapterSize = (ch: number) => LEVELS.filter((l) => l.ch === ch).length;
const earned = (): (Clue & { ch: number; level: number })[] =>
  (game?.clues ?? []).slice().sort((a, b) => a - b).map((i) => ({ ...LEVELS[i].clue, ch: LEVELS[i].ch, level: i }));

function save() { if (game && !debug.sandbox) writeSave(game); }

function applyTextSize() {
  document.documentElement.dataset.text = String(settings.textSize);
  document.documentElement.classList.toggle('reduce-motion', settings.reducedMotion);
}

// ---------- rendering ----------

function render() {
  puzzle?.destroy?.();
  puzzle = null;
  clearTimeout(solvedTimer);
  app.innerHTML = '';
  applyTextSize();
  if (!game) return renderTitle();
  switch (game.phase) {
    case 'name': return renderName();
    case 'chapter': return renderChapter();
    case 'intro': case 'reveal': return renderStory();
    case 'puzzle': return renderPuzzle();
    case 'end': return renderEnd();
  }
}

function header(): HTMLElement {
  const l = cur();
  return h('header', { class: 'top' },
    h('div', { class: 'top-text' },
      h('small', { text: `Chapter ${l.ch + 1} · ${levelInChapter(game!.level)}/${chapterSize(l.ch)}` }),
      h('strong', { text: l.title })),
    h('div', { class: 'top-btns' },
      h('button', { class: 'icon-btn', 'aria-label': 'Evidence board', text: '▤', onclick: () => openEvidence() }),
      h('button', { class: 'icon-btn', 'aria-label': 'Menu', text: '☰', onclick: () => openMenu() })),
    h('div', { class: 'progress', style: { width: `${((game!.level + (game!.phase === 'reveal' ? 1 : 0)) / LEVELS.length) * 100}%` } }));
}

function renderTitle() {
  const saved = loadSave(LEVELS.length);
  const bg = h('div', { class: 'title-art' });
  if (TITLE_ART) bg.append(h('img', { src: TITLE_ART, alt: '' }));
  else bg.append(sceneArt('exterior'));
  const title = h('h1', { class: 'title-logo' }, 'THE LAST', h('br'), 'CHECK-IN');
  title.addEventListener('click', () => {
    if (++debug.titleTaps >= 7 && !debug.enabled) { debug.enabled = true; toast('Developer tools on for this session.'); }
  });
  const btns = h('div', { class: 'title-btns' });
  if (saved && !saved.finished) btns.append(h('button', { class: 'btn primary', text: `Continue · Chapter ${LEVELS[Math.min(saved.level, LEVELS.length - 1)].ch + 1}`, onclick: () => { unlockAudio(); debug.sandbox = false; game = saved; render(); } }));
  btns.append(h('button', { class: `btn${saved && !saved.finished ? '' : ' primary'}`, text: saved ? 'New case' : 'Begin your shift', onclick: () => {
    unlockAudio();
    if (saved && !saved.finished) confirmBox('Start a new case? Your current progress will be lost.', 'Start again', startNew);
    else startNew();
  } }));
  btns.append(h('div', { class: 'btn-row' },
    h('button', { class: 'btn ghost', text: 'Settings', onclick: () => openSettings() }),
    h('button', { class: 'btn ghost', text: 'Credits', onclick: () => openCredits() })));
  app.append(h('section', { class: 'screen title' }, bg,
    h('div', { class: 'title-copy' }, h('p', { class: 'eyebrow', text: 'A Mariner Motel mystery' }), title,
      h('p', { class: 'tagline', text: 'Nina never checked out. Someone wants the evidence buried.' })),
    btns, h('p', { class: 'fine', text: '28 puzzles · 4 chapters · no timers · no ads · plays offline' })));
}

function startNew() {
  clearSave();
  debug.sandbox = false;
  game = newSave();
  save();
  render();
}

function renderName() {
  const input = h('input', { class: 'name-input', type: 'text', maxlength: 20, autocomplete: 'given-name', placeholder: DEFAULT_NAME, 'aria-label': 'Your name', value: game!.name });
  const go = () => {
    game!.name = (input as HTMLInputElement).value.trim().slice(0, 20) || DEFAULT_NAME;
    game!.phase = 'chapter'; sfx('tap'); save(); render();
  };
  input.addEventListener('keydown', (e) => { if (e.key === 'Enter') go(); });
  app.append(h('section', { class: 'screen name' },
    sceneArt('reception', 'name-art'),
    h('div', { class: 'name-card' },
      h('p', { class: 'eyebrow', text: 'Mariner Motel · Night staff' }),
      h('h2', { text: 'Your name badge' }),
      h('p', { text: 'Nina trained you this week. She asked you to come in early tonight. You\'re running late.' }),
      input,
      h('button', { class: 'btn primary', text: 'Start the shift', onclick: go }))));
  setTimeout(() => input.focus(), 50);
}

function renderChapter() {
  const ch = cur().ch;
  audioScene(cur().scene, ch);
  sfx('chapter');
  const next = () => { game!.phase = 'intro'; game!.line = 0; save(); render(); };
  const el = h('section', { class: 'screen chapter', tabindex: 0, onclick: next },
    h('p', { class: 'eyebrow', text: `Chapter ${ch + 1} of ${CHAPTERS.length}` }),
    h('h2', { text: CHAPTERS[ch].name }),
    h('p', { class: 'chapter-sub', text: CHAPTERS[ch].subtitle }),
    h('p', { class: 'fine', text: 'Tap to continue' }));
  el.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') next(); });
  app.append(el);
  el.focus();
}

function renderStory() {
  const l = cur();
  const lines = game!.phase === 'intro' ? l.intro : l.reveal;
  game!.line = Math.min(game!.line, lines.length - 1);
  const [speaker, text] = lines[game!.line];
  audioScene(l.scene, l.ch, game!.phase === 'reveal' && game!.level === LEVELS.length - 1 && game!.line > 2);
  duckMusic(true);

  const art = sceneArt(l.scene);
  const portrait = portraitFor(speaker);
  if (portrait) art.append(h('img', { class: 'portrait', src: portrait, alt: speaker.split(' ')[0] }));
  if (/RECORDING|PHONE|INTERCOM|DISTANT/.test(speaker)) art.classList.add('remote');

  const who = speaker === 'YOU' ? (game!.name || DEFAULT_NAME).toUpperCase() : speaker;
  const panel = h('div', { class: `dialogue${speaker === 'NARRATOR' ? ' narrator' : ''}` },
    speaker === 'NARRATOR' ? null : h('p', { class: 'speaker', text: who }),
    h('p', { class: 'line', text: fill(text) }),
    h('p', { class: 'tap-hint', text: `Tap to continue · ${game!.line + 1}/${lines.length}` }));

  const skip = h('button', { class: 'link-btn', text: game!.phase === 'intro' ? 'Skip to the puzzle ›' : 'Skip ›', onclick: (e: Event) => { e.stopPropagation(); finishLines(); } });
  const back = h('button', { class: 'link-btn', text: '‹ Back', disabled: game!.line === 0 ? true : undefined, onclick: (e: Event) => { e.stopPropagation(); if (game!.line > 0) { game!.line--; save(); render(); } } });

  const screen = h('section', { class: 'screen story', tabindex: 0 }, header(), art, panel, h('div', { class: 'story-nav' }, back, skip));
  screen.addEventListener('click', (e) => { if (!(e.target as HTMLElement).closest('button')) advance(); });
  screen.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); advance(); } });
  app.append(screen);
  screen.focus({ preventScroll: true });
}

function advance() {
  const l = cur();
  const lines = game!.phase === 'intro' ? l.intro : l.reveal;
  if (game!.line < lines.length - 1) {
    game!.line++;
    const sp = lines[game!.line][0];
    sfx(sp.includes('PHONE') ? 'phone' : /RECORDING|INTERCOM/.test(sp) ? 'static' : 'tap');
    save(); render();
  } else finishLines();
}

function finishLines() {
  if (game!.phase === 'intro') { game!.phase = 'puzzle'; save(); render(); return; }
  nextLevel();
}

function nextLevel() {
  const g = game!;
  if (g.level >= LEVELS.length - 1) { g.phase = 'end'; g.finished = true; save(); render(); return; }
  const prevCh = cur().ch;
  g.level++; g.line = 0;
  g.phase = cur().ch !== prevCh ? 'chapter' : 'intro';
  sfx('door'); save(); render();
}

function renderPuzzle() {
  const l = cur();
  audioScene(l.scene, l.ch);
  duckMusic(false);
  const hints = game!.hints[game!.level] ?? 0;
  const boardRoot = h('div', { class: 'board-root' });
  const status = h('p', { class: 'status', 'aria-live': 'polite' });
  const hintBox = h('div', { class: 'hint-box' });
  const showHints = (n: number) => {
    hintBox.innerHTML = '';
    for (let i = 0; i < n && i < 2; i++) hintBox.append(h('p', null, h('strong', { text: `Hint ${i + 1}: ` }), l.hints[i]));
  };
  showHints(hints);

  const hintBtn = h('button', { class: 'btn', text: hints < 2 ? `Hint ${hints + 1}` : 'Skip puzzle', onclick: () => {
    const n = game!.hints[game!.level] ?? 0;
    if (n < 2) { game!.hints[game!.level] = n + 1; save(); showHints(n + 1); sfx('paper'); hintBtn.textContent = n + 1 < 2 ? 'Hint 2' : 'Skip puzzle'; }
    else confirmBox('Skip this puzzle? You still get the evidence and the story carries on. No penalty.', 'Skip it', () => win(true));
  } });

  const actions = h('div', { class: 'puzzle-actions' },
    h('button', { class: 'btn', text: '↺ Reset', onclick: () => { sfx('tap'); mount(); } }), hintBtn);
  if (debug.enabled) actions.append(h('button', { class: 'btn dev', text: 'DEV skip', onclick: () => win(true) }));

  app.append(h('section', { class: 'screen puzzle' }, header(),
    h('div', { class: 'puzzle-head' },
      h('p', { class: 'eyebrow', text: `${KIND_LABEL[l.puzzle.kind]} · ${l.title}` }),
      h('p', { class: 'task', text: fill(l.task) })),
    boardRoot, status, hintBox, actions,
    h('p', { class: 'fine', text: 'No timer. No penalties. Progress saves automatically.' })));

  let solved = false;
  const mount = () => {
    puzzle?.destroy?.();
    boardRoot.innerHTML = '';
    solved = false;
    puzzle = mountPuzzle(l.puzzle, {
      root: boardRoot,
      seed: (game!.level + 1) * 7919,
      reducedMotion: settings.reducedMotion,
      sfx, haptic,
      status: (m) => { status.textContent = m; },
      solved: () => { if (solved) return; solved = true; haptic(30); solvedTimer = window.setTimeout(() => win(false), settings.reducedMotion ? 300 : 900); },
      clues: earned(),
    });
  };
  mount();
}

function win(skipped: boolean) {
  const g = game!;
  if (g.phase !== 'puzzle') return;
  if (!g.clues.includes(g.level)) g.clues.push(g.level);
  g.phase = 'reveal'; g.line = 0;
  save();
  sfx('clue');
  const c = cur().clue;
  showOverlay(h('div', { class: 'clue-card', role: 'dialog', 'aria-label': 'New evidence' },
    h('p', { class: 'eyebrow', text: skipped ? 'Evidence added · puzzle skipped' : 'Evidence added' }),
    h('h3', { text: c.title }),
    h('p', { text: fill(c.text) }),
    h('button', { class: 'btn primary', text: 'Continue', onclick: () => { closeOverlay(); render(); } })), false);
}

function renderEnd() {
  audioScene('exterior', 3, true);
  duckMusic(false);
  const hintsUsed = Object.values(game!.hints).reduce((a, b) => a + b, 0);
  app.append(h('section', { class: 'screen end' }, sceneArt('exterior', 'end-art'),
    h('div', { class: 'end-card' },
      h('p', { class: 'eyebrow', text: 'Case closed' }),
      h('h2', { text: 'Before dawn' }),
      h('p', { text: fill('Nina is safe. Daniel Price is in custody. Owen Mercer is answering questions he has avoided for seven years. Mara Ward\'s case is open again.') }),
      h('p', { text: fill('And {name} has a story nobody at the Mariner will let them forget.') }),
      h('p', { class: 'fine', text: `${game!.clues.length} pieces of evidence · ${hintsUsed} hint${hintsUsed === 1 ? '' : 's'} used` }),
      h('div', { class: 'title-btns' },
        h('button', { class: 'btn', text: 'Evidence board', onclick: () => openEvidence() }),
        h('button', { class: 'btn primary', text: 'Back to the title', onclick: () => { game = null; render(); } })))));
}

// ---------- overlays ----------

function showOverlay(content: HTMLElement, dismissable = true) {
  closeOverlay();
  overlay = h('div', { class: 'overlay', role: 'presentation' }, content);
  if (dismissable) overlay.addEventListener('click', (e) => { if (e.target === overlay) closeOverlay(); });
  document.body.append(overlay);
  const first = content.querySelector<HTMLElement>('button, input, [tabindex]');
  first?.focus();
}
function closeOverlay() { overlay?.remove(); overlay = null; }
document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && overlay && !overlay.querySelector('.clue-card')) closeOverlay(); });

function sheet(title: string, ...body: (HTMLElement | null)[]) {
  return h('div', { class: 'sheet', role: 'dialog', 'aria-label': title },
    h('div', { class: 'sheet-head' }, h('h3', { text: title }), h('button', { class: 'icon-btn', 'aria-label': 'Close', text: '✕', onclick: closeOverlay })),
    ...body);
}

function openEvidence() {
  const list = earned();
  const body = h('div', { class: 'evidence' });
  if (!list.length) body.append(h('p', { class: 'fine', text: 'Nothing yet. Every solved puzzle adds evidence here.' }));
  CHAPTERS.forEach((c, ch) => {
    const items = list.filter((x) => x.ch === ch);
    if (!items.length) return;
    body.append(h('h4', { text: `Chapter ${ch + 1} · ${c.name}` }));
    items.forEach((x) => body.append(h('article', { class: 'ev-item' }, h('strong', { text: x.title }), h('p', { text: fill(x.text) }))));
  });
  showOverlay(sheet('Evidence board', body));
}

function openMenu() {
  showOverlay(sheet('Paused',
    h('div', { class: 'menu-list' },
      h('button', { class: 'btn primary', text: 'Resume', onclick: closeOverlay }),
      h('button', { class: 'btn', text: 'Evidence board', onclick: openEvidence }),
      h('button', { class: 'btn', text: 'Settings', onclick: openSettings }),
      debug.enabled ? h('button', { class: 'btn dev', text: 'Developer tools', onclick: openDebug }) : null,
      h('button', { class: 'btn ghost', text: 'Back to the title', onclick: () => { closeOverlay(); game = null; debug.sandbox = false; render(); } }))));
}

function openSettings() {
  const slider = (key: 'master' | 'music' | 'ambience' | 'effects', label: string) => {
    const input = h('input', { type: 'range', min: 0, max: 1, step: 0.05, value: settings[key], 'aria-label': label });
    input.addEventListener('input', () => { settings[key] = Number((input as HTMLInputElement).value); mix(); saveSettings(); });
    input.addEventListener('change', () => sfx('tap'));
    return h('label', { class: 'set-row' }, h('span', { text: label }), input);
  };
  const toggle = (key: 'muted' | 'reducedMotion' | 'haptics', label: string) => {
    const input = h('input', { type: 'checkbox', checked: settings[key] ? true : undefined });
    input.addEventListener('change', () => { settings[key] = (input as HTMLInputElement).checked; mix(); saveSettings(); applyTextSize(); });
    return h('label', { class: 'set-row' }, h('span', { text: label }), input);
  };
  const sizes = h('div', { class: 'seg' }, ...([1, 2, 3] as const).map((n) => h('button', {
    class: `btn${settings.textSize === n ? ' primary' : ''}`, text: ['Normal', 'Large', 'Larger'][n - 1],
    onclick: () => { settings.textSize = n; saveSettings(); applyTextSize(); openSettings(); },
  })));
  showOverlay(sheet('Settings',
    slider('master', 'Master volume'), slider('music', 'Music'), slider('ambience', 'Ambience'), slider('effects', 'Effects'),
    toggle('muted', 'Mute everything'), toggle('reducedMotion', 'Reduce motion'), toggle('haptics', 'Vibration (Android)'),
    h('div', { class: 'set-row' }, h('span', { text: 'Text size' }), sizes)));
}

function openCredits() {
  showOverlay(sheet('Credits',
    h('p', { text: 'Story, puzzles and code: made for one particular player.' }),
    h('p', { text: 'Art and sound in this build are placeholders. See ASSETS.md in the project for what each one will become.' })));
}

function openDebug() {
  const jump = h('div', { class: 'dbg-levels' }, ...LEVELS.map((l, i) => h('button', {
    class: 'btn', text: `${String(i + 1).padStart(2, '0')} ${l.puzzle.kind}`,
    title: l.title,
    onclick: () => { debug.sandbox = true; game = { ...(game ?? newSave(DEFAULT_NAME)), level: i, phase: 'puzzle', line: 0, clues: LEVELS.slice(0, i).map((_, k) => k) }; closeOverlay(); render(); },
  })));
  const sounds = h('div', { class: 'dbg-levels' }, ...(['tap', 'pick', 'place', 'invalid', 'solve', 'clue', 'power', 'door', 'latch', 'ratchet', 'pour', 'combo', 'static', 'phone', 'chapter'] as const)
    .map((s) => h('button', { class: 'btn', text: s, onclick: () => sfx(s) })));
  showOverlay(sheet('Developer tools',
    h('p', { class: 'fine', text: 'Jumping opens a sandbox that never overwrites the real save. Return to the title and Continue to get back.' }),
    h('h4', { text: 'Jump to puzzle' }), jump, h('h4', { text: 'Sound audition' }), sounds));
}

function confirmBox(text: string, yes: string, onYes: () => void) {
  showOverlay(sheet('Are you sure?', h('p', { text }), h('div', { class: 'menu-list' },
    h('button', { class: 'btn primary', text: yes, onclick: () => { closeOverlay(); onYes(); } }),
    h('button', { class: 'btn ghost', text: 'Cancel', onclick: closeOverlay }))));
}

function toast(text: string) {
  const t = h('div', { class: 'toast', role: 'status', text });
  document.body.append(t);
  setTimeout(() => t.remove(), 2400);
}

// ---------- test hooks (developer mode only) ----------

declare global { interface Window { __lci?: unknown } }
function exposeHooks() {
  if (!debug.enabled) return;
  window.__lci = {
    state: () => (game ? { ...game } : null),
    levels: LEVELS.length,
    skip: () => { if (game?.phase === 'puzzle') win(true); },
    finishScene: () => { if (game && (game.phase === 'intro' || game.phase === 'reveal')) finishLines(); else if (game?.phase === 'chapter') { game.phase = 'intro'; render(); } },
    closeOverlay: () => { closeOverlay(); render(); },
    jump: (i: number) => { debug.sandbox = true; game = { ...(game ?? newSave(DEFAULT_NAME)), level: i, phase: 'puzzle', line: 0, clues: LEVELS.slice(0, i).map((_, k) => k) }; closeOverlay(); render(); },
  };
}

export function start() {
  applyTextSize();
  exposeHooks();
  document.addEventListener('pointerdown', unlockAudio, { once: true });
  render();
}
