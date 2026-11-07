"""Automated 28-stage developer skip walkthrough, verifying every clue and ending.
Requires: pip install playwright; Chromium installed by `playwright install chromium`
or available on the system path.
Run: python tests/full_case_debug.py
Uses in-memory HTML due to environments that block direct navigation.
"""
from pathlib import Path
from shutil import which
from playwright.sync_api import sync_playwright

root = Path(__file__).resolve().parents[1]
html = (root / 'dist' / 'The_Last_Check_In.html').read_text(encoding='utf-8')
needle = "new URLSearchParams(window.location.search).get('debug')==='1'||window.location.hash==='#debug'"
assert needle in html, 'Debug URL activation changed; update test to use the new developer activation path.'

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True, executable_path=which('chromium') or which('google-chrome') or None)
    page = browser.new_page(viewport={'width':390,'height':844},is_mobile=True,has_touch=True)
    errors = []
    page.on('pageerror', lambda e: errors.append(str(e)))
    page.set_content(html.replace(needle, 'true'))  # Test-only simulation of ?debug=1
    page.locator('[data-act="new"]').click()

    for level in range(28):
        # Advance the dialogue to the next puzzle using the same game action as a tap.
        state = page.evaluate('''() => {
            let lines = 0;
            while (game.phase !== 'puzzle' && !atEnd() && lines < 30) {
                nextDialogue(); lines++;
            }
            return {level:game.level, phase:game.phase};
        }''')
        assert state == {'level':level,'phase':'puzzle'}, f'Level {level+1}: {state}'
        page.locator('[data-act="debugSkip"]').click()
        state = page.evaluate('({phase:game.phase, clues:game.clues.length})')
        assert state == {'phase':'reveal','clues':level+1}, f'Level {level+1}: {state}'
        assert page.evaluate('game.clues.at(-1).title===current().clue.title'), f'Wrong clue at {level+1}'

    state = page.evaluate('''() => {
        let lines = 0;
        while (!atEnd() && lines < 30) {nextDialogue(); lines++;}
        return {end:atEnd(), level:game.level, clues:game.clues.length, finished:game.finished};
    }''')
    assert state == {'end':True,'level':28,'clues':28,'finished':True},state
    assert page.locator('.end-hero').count() == 1
    assert not errors,errors
    print('PASS 28 stages · 28 developer skips · 28 correct clue awards · 4 chapters · ending')
    browser.close()
