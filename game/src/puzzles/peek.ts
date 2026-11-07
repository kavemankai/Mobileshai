// The case file: every clue earned so far, openable from inside a puzzle that needs a deduction.

import { h } from '../core/dom';
import type { Clue } from '../core/types';

export function evidencePeek(clues: Clue[], label = 'Check the case file'): HTMLElement {
  return h('details', { class: 'cx-peek' },
    h('summary', { text: label }),
    h('div', { class: 'peek-list' }, ...(clues.length ? clues.map((c) => h('p', null, h('strong', { text: c.title + ': ' }), c.text)) : [h('p', { text: 'Nothing in the file yet.' })])));
}
