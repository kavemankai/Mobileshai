"""Basic browser smoke test for the project. Requires pip install playwright and installed Chromium.
Run: python tests/smoke_playwright.py
This uses set_content() to also work in browser sandboxes that disallow file:// URLs.
"""
from pathlib import Path
from shutil import which
from playwright.sync_api import sync_playwright
root=Path(__file__).resolve().parents[1]
html=(root/'dist'/'The_Last_Check_In.html').read_text(encoding='utf-8')
needle="new URLSearchParams(window.location.search).get('debug')==='1'||window.location.hash==='#debug'"
with sync_playwright() as p:
    browser=p.chromium.launch(headless=True,executable_path=which('chromium') or which('google-chrome') or None)
    for width,height in ((360,780),(412,915)):
        page=browser.new_page(viewport={'width':width,'height':height},is_mobile=True,has_touch=True)
        errors=[]
        page.on('pageerror',lambda e:errors.append(str(e)))
        page.set_content(html)
        assert page.locator('.devindicator').count()==0
        page.locator('[data-act="new"]').click()
        for _ in range(50):
            if page.locator('[data-act="reset"]').count():break
            page.locator('[data-act="advance"]').last.click()
        assert page.locator('[data-act="reset"]').count()==1
        assert page.locator('[data-act="debugSkip"]').count()==0
        assert not errors,errors
        page.close()
        if needle not in html:
            raise RuntimeError('Debug flag expression moved: update smoke test for new debug enabling method')
        page=browser.new_page(viewport={'width':width,'height':height},is_mobile=True,has_touch=True)
        errors=[]
        page.on('pageerror',lambda e:errors.append(str(e)))
        # The test-only substitution simulates ?debug=1 without file:// navigation.
        page.set_content(html.replace(needle,'true'))
        page.locator('[data-act="new"]').click()
        for _ in range(50):
            if page.locator('[data-act="debugSkip"]').count():break
            page.locator('[data-act="advance"]').last.click()
        assert page.locator('[data-act="debugSkip"]').count()==1
        page.locator('[data-act="debugSkip"]').click()
        assert page.evaluate('game.phase')=='reveal'
        assert page.evaluate('game.clues.length')==1
        assert not errors,errors
        page.close()
        print(f'PASS {width}x{height}: normal mode hidden, debug skip yields clue')
    browser.close()
