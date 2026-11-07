// Escape room: tap things in the scene, collect items, use them on other things.
// Placeholder mode draws every hotspot as a labelled prop card. In the art pass, set
// `PROPS_VISIBLE = false` once the painted scene shows the objects itself.

import { ITEM_ICONS } from '../assets/manifest';
import { sceneArt } from '../core/art';
import { h } from '../core/dom';
import type { Hotspot, PuzzleMount, RoomDef } from '../core/types';

export const PROPS_VISIBLE = true;

export interface RoomState { flags: Set<string>; items: Set<string>; used: Set<string> }

export const spotVisible = (s: Hotspot, st: RoomState) =>
  (!s.visibleIf || st.flags.has(s.visibleIf)) && (!s.hiddenIf || !st.flags.has(s.hiddenIf));

/** Applies a tap with an optional selected item. Pure apart from mutating `st`. */
export function useSpot(def: RoomDef, st: RoomState, s: Hotspot, item: string | null): { text: string; ok: boolean; keypad?: boolean } {
  if (s.keypad) return { text: '', ok: true, keypad: true };
  if (st.used.has(s.id)) return { text: s.doneText ?? s.text, ok: true };
  if (s.needs && item !== s.needs) {
    return { text: s.needsText ?? (st.items.has(s.needs) ? `Try using the ${def.items[s.needs].label.toLowerCase()} here.` : s.text), ok: false };
  }
  st.used.add(s.id);
  if (s.needs && s.consumes) st.items.delete(s.needs);
  if (s.gives) st.items.add(s.gives);
  if (s.sets) st.flags.add(s.sets);
  return { text: s.text, ok: true };
}

export const mountRoom: PuzzleMount<RoomDef> = (def, ctx) => {
  const st: RoomState = { flags: new Set(), items: new Set(), used: new Set() };
  let selected: string | null = null;
  let done = false;

  const stage = h('div', { class: 'room-stage' });
  const art = sceneArt(def.scene, 'room-art');
  const layer = h('div', { class: 'room-layer' });
  stage.append(art, layer);
  const inv = h('div', { class: 'room-inv', role: 'toolbar', 'aria-label': 'Inventory' });
  const msg = h('p', { class: 'room-msg', 'aria-live': 'polite' });
  const modal = h('div', { class: 'room-modal', hidden: true });

  const say = (t: string) => { msg.textContent = t; };

  const draw = () => {
    layer.innerHTML = '';
    for (const s of def.hotspots) {
      if (!spotVisible(s, st)) continue;
      const b = h('button', {
        class: `room-spot${PROPS_VISIBLE ? ' prop' : ''}${st.used.has(s.id) && !s.keypad ? ' used' : ''}`,
        'aria-label': s.label,
        style: { left: `${s.x}%`, top: `${s.y}%`, width: `${s.w}%`, height: `${s.h}%` },
      }, PROPS_VISIBLE ? h('span', { class: 'room-icon', text: s.icon }) : null, PROPS_VISIBLE ? h('span', { class: 'room-label', text: s.label }) : null);
      b.addEventListener('click', () => tap(s));
      layer.append(b);
    }
    inv.innerHTML = '';
    if (!st.items.size) inv.append(h('span', { class: 'room-inv-empty', text: 'Pockets: empty' }));
    for (const id of st.items) {
      const it = def.items[id];
      const b = h('button', { class: `room-item${selected === id ? ' sel' : ''}`, 'aria-pressed': selected === id ? 'true' : 'false', 'aria-label': `${it.label}${selected === id ? ', selected' : ''}` }, ITEM_ICONS[id] ? h('img', { class: 'room-item-img', src: ITEM_ICONS[id], alt: '' }) : h('span', { text: it.icon }), h('small', { text: it.label }));
      b.addEventListener('click', () => { selected = selected === id ? null : id; ctx.sfx('pick'); draw(); say(selected ? `Holding: ${it.label}. Tap where to use it.` : ''); });
      inv.append(b);
    }
  };

  const tap = (s: Hotspot) => {
    if (done) return;
    const r = useSpot(def, st, s, selected);
    if (r.keypad) { openKeypad(); return; }
    if (r.ok) {
      if (s.gives) { ctx.sfx('found'); ctx.haptic(8); }
      else if (s.needs) { ctx.sfx('latch'); selected = null; }
      else ctx.sfx('tap');
    } else ctx.sfx('invalid');
    say(r.text);
    draw();
    checkGoal();
  };

  const checkGoal = () => {
    if (!done && st.flags.has(def.goal)) { done = true; stage.classList.add('solved'); ctx.sfx('door'); ctx.solved(); }
  };

  const openKeypad = () => {
    const kp = def.keypad!;
    let entry = '';
    modal.hidden = false;
    modal.innerHTML = '';
    const display = h('div', { class: 'kp-display', 'aria-live': 'polite' });
    const show = () => { display.textContent = entry.padEnd(kp.code.length, '·'); };
    const keys = h('div', { class: 'kp-keys' });
    const press = (k: string) => {
      if (k === 'C') entry = '';
      else if (k === '✓') {
        if (entry === kp.code) { st.flags.add(kp.sets); ctx.sfx('door'); modal.hidden = true; say('The lock releases.'); draw(); checkGoal(); return; }
        ctx.sfx('invalid'); display.classList.add('shake'); setTimeout(() => display.classList.remove('shake'), 400); entry = '';
      } else if (entry.length < kp.code.length) { entry += k; ctx.sfx('click'); }
      show();
    };
    for (const k of ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '✓']) keys.append(h('button', { class: 'kp-key', text: k, 'aria-label': k === 'C' ? 'Clear' : k === '✓' ? 'Enter' : k, onclick: () => press(k) }));
    modal.append(h('div', { class: 'kp-box' }, h('p', { class: 'kp-label', text: kp.label }), display, keys, h('button', { class: 'btn ghost', text: 'Step back', onclick: () => { modal.hidden = true; } })));
    show();
  };

  ctx.root.append(h('div', { class: 'board-frame room-frame' }, stage, msg, inv, modal));
  draw();
  say('Look around. Tap anything that stands out.');
  ctx.status('Select an item in your pockets, then tap where to use it.');
  return {};
};
