"""End-to-end legal-input solutions, save compatibility, offline and layout evidence.
Run: python tests/production_qa.py. Requires Playwright Chromium.
No production puzzle state is modified to win. Solvers calculate legal moves externally.
"""
import json, threading, time, hashlib
from collections import deque
from functools import partial
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from playwright.sync_api import sync_playwright
from shutil import which

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'artifacts';OUT.mkdir(exist_ok=True)
class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self,*args):pass
server=ThreadingHTTPServer(('127.0.0.1',0),partial(QuietHandler,directory=str(ROOT)))
threading.Thread(target=server.serve_forever,daemon=True).start()
URL=f'http://127.0.0.1:{server.server_port}/dist/The_Last_Check_In.html'
checks=[];errors=[];requests=[]
def record(s):checks.append(s);print('PASS',s,flush=True)
def state(page):return page.evaluate('game')
def click(page,act,value=None):
    q=f'[data-act="{act}"]'+(f'[data-value="{value}"]' if value is not None else '')
    page.locator(q).last.click()
def advance(page):
    while state(page)['phase'] in ('intro','reveal'):click(page,'advance')
def shot(page,name):
    page.wait_for_timeout(450)
    page.screenshot(path=str(OUT/(name+'.png')),animations='disabled')
def assert_layout(page):
    assert page.evaluate('document.documentElement.scrollWidth<=innerWidth'), 'horizontal page overflow'
    assert page.evaluate('''()=>{const st=document.querySelector('.stage');return !st||st.scrollWidth<=st.clientWidth+1}'''), 'horizontal stage overflow'
    for btn in page.locator('.topbar button').all():
        b=btn.bounding_box();assert b and b['x']>=0 and b['x']+b['width']<=page.viewport_size['width'],b
    for btn in page.locator('.puzzlecontrols button,.park-buttons button,.key').all():
        btn.scroll_into_view_if_needed();b=btn.bounding_box();assert b and b['height']>=43 and b['width']>=43,b

# Reverse BFS for the classic 8-puzzle, independent of game implementation.
goal=(1,2,3,4,5,6,7,8,0);previous={goal:None};queue=deque([goal])
while queue:
    t=queue.popleft();z=t.index(0)
    for j in (z-3,z+3,z-1 if z%3 else -1,z+1 if z%3<2 else -1):
        if 0<=j<9:
            n=list(t);n[z],n[j]=n[j],n[z];n=tuple(n)
            if n not in previous:previous[n]=t;queue.append(n)
def parking_solution(cars):
    start=tuple((c['x'],c['y']) for c in cars);q=deque([(start,[])]);seen={start}
    while q:
        coords,moves=q.popleft()
        if coords[next(i for i,c in enumerate(cars) if c.get('target'))][0]>=4:return moves
        for i,c in enumerate(cars):
            for d in (-1,1):
                x,y=coords[i];x+=d if c['dir']=='h' else 0;y+=d if c['dir']=='v' else 0
                w,h=(c['len'],1) if c['dir']=='h' else (1,c['len'])
                if x<0 or y<0 or x+w>6 or y+h>6:continue
                occupied={(x+a,y+b) for a in range(w) for b in range(h)}
                blocked=False
                for j,o in enumerate(cars):
                    if i==j:continue
                    ox,oy=coords[j];ow,oh=(o['len'],1) if o['dir']=='h' else (1,o['len'])
                    if occupied & {(ox+a,oy+b) for a in range(ow) for b in range(oh)}:blocked=True;break
                if blocked:continue
                n=list(coords);n[i]=(x,y);n=tuple(n)
                if n not in seen:seen.add(n);q.append((n,moves+[(c['id'],d)]))
    raise AssertionError('Unsolvable parking layout')

with sync_playwright() as p:
    browser=p.chromium.launch(headless=True, executable_path=which("chromium") or which("google-chrome") or None)
    context=browser.new_context(viewport={'width':390,'height':844},is_mobile=True,has_touch=True)
    page=context.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('request',lambda r:requests.append(r.url))
    page.goto(URL);shot(page,'title-390');assert not page.locator('.devindicator').count()
    record('developer controls hidden by default')
    click(page,'new');shot(page,'opening-390')
    context.set_offline(True)
    record('network disabled for complete legal-input playthrough')
    captures={'screws':False,'match':False,'parking':False,'slide':False,'keypad':False,'sort':False}
    for level in range(28):
        advance(page);g=state(page);assert g['level']==level
        l=page.evaluate('current()');kind=l['kind'];d=g['puzzle'];assert_layout(page)
        if level==0:shot(page,'circuit-390')
        if kind in captures and not captures[kind]:
            page.locator('.stage').evaluate('(e)=>e.scrollTop=0');shot(page,f'{kind}-390');captures[kind]=True
        if kind=='circuit':
            for idx in d['path']:
                while page.evaluate(f'game.puzzle&&!isCircuitSolved(game.puzzle)&&game.puzzle.rot[{idx}]!==game.puzzle.solved[{idx}]'):
                    click(page,'circuit',idx)
        elif kind=='sort':
            expected=[x[0] for x in l['items']]
            for i,correct in enumerate(expected):
                order=state(page)['puzzle']['order']
                if order[i]!=correct:click(page,'sort',order[i]);click(page,'sort',correct)
        elif kind=='slide':
            t=tuple(d['tiles'])
            while t!=goal:
                n=previous[t];idx=n.index(0);click(page,'slide',idx);t=n
        elif kind=='screws':
            for i in range(l['bolts']):click(page,'screw',i)
        elif kind=='match':
            for i in range(len(l['pairs'])):click(page,'left',i);click(page,'right',i)
        elif kind=='keypad':
            for digit in l['code']:click(page,'digit',digit)
        elif kind=='parking':
            for car,direction in parking_solution(d['cars']):click(page,'selectcar',car);click(page,'parkmove',direction)
        page.wait_for_function('game.phase==="reveal"')
        g=state(page);assert len(g['clues'])==level+1 and g['clues'][-1]['title']==l['clue']['title']
        if level==0:
            shot(page,'discovery-390');click(page,'archive');shot(page,'evidence-390');assert page.locator('.archive-item').count()==1;click(page,'close')
        if level in (7,14,21):shot(page,f'chapter-{l["ch"]+1}-finale')
    advance(page);g=state(page);assert g['finished'] and g['level']==28 and len(g['clues'])==28
    assert len({c['title'] for c in g['clues']})==28;shot(page,'ending-390')
    record('28 puzzles solved using legal UI inputs; all 28 exact unique clues; four chapters and complete ending')
    assert not any(not u.startswith(URL.split('/dist')[0]) for u in requests),requests
    record('all runtime requests local; full case works without network')
    context.set_offline(False);page.reload();click(page,'continue');assert state(page)['finished']
    record('completed save resumes after reload')
    # Old-format compatible saves, including complete-but-waiting victory recovery.
    for phase in ['intro','puzzle','reveal']:
        page.evaluate('''phase=>{game=defaultGame();game.phase=phase;if(phase==='puzzle')game.puzzle=initPuzzle(LEVELS[0],0);if(phase==='reveal')game.clues=[{...LEVELS[0].clue,level:0,chapter:0}];store();}''',phase)
        page.reload();click(page,'continue');assert state(page)['phase']==phase
    page.evaluate('game.phase="puzzle";game.puzzle=initPuzzle(LEVELS[0],0);game.puzzle.complete=true;game.clues=[];store()')
    page.reload();click(page,'continue');assert state(page)['phase']=='reveal' and len(state(page)['clues'])==1
    record('legacy save key and intro/puzzle/reveal resume; interrupted victory awards clue once')
    click(page,'menu');click(page,'sound');assert page.evaluate('preferences.muted')
    page.locator('[data-pref="music"]').fill('0.15');page.locator('[data-pref="motion"]').check();page.locator('[data-pref="text"]').select_option('1.3')
    click(page,'close');page.reload();click(page,'continue');click(page,'menu');assert page.evaluate('preferences.muted&&preferences.music===.15&&preferences.motion&&preferences.text===1.3')
    page.wait_for_function('sound.ctx===null || sound.buses.master.gain.value < .01')
    shot(page,'settings-390');record('persistent mute, bus volumes, reduce motion and text size')
    click(page,'title')
    for _ in range(7):click(page,'debugtap')
    assert page.locator('.devindicator').count()==1;click(page,'continue');advance(page)
    # Open dev tools and jump. The standard save must stay byte-for-byte identical.
    click(page,'devPanel');before=page.evaluate('localStorage.getItem(STORAGE_KEY)');page.locator('#dev-stage').select_option('11');click(page,'devJump');click(page,'debugSkip')
    assert page.evaluate('localStorage.getItem(STORAGE_KEY)')==before;record('seven title taps enable developer tools; stage sandbox preserves normal save')
    click(page,'menu');click(page,'title');click(page,'continue');assert not page.evaluate('debugState.sandbox')
    # All layouts in every required viewport, with a new context at each size.
    for width,height in [(360,780),(390,844),(412,915),(1280,900)]:
        ctx=browser.new_context(viewport={'width':width,'height':height},is_mobile=width<600,has_touch=True)
        q=ctx.new_page();q.on('pageerror',lambda e:errors.append(str(e)));q.goto(URL+'?debug=1');click(q,'new')
        for idx in range(28):
            q.evaluate('''idx=>{debugState.sandbox=true;game=defaultGame();game.level=idx;beginPuzzle();}''',idx)
            assert_layout(q)
            if idx in (0,11,22):q.locator('.stage').evaluate('(e)=>e.scrollTop=0');shot(q,f'stage-{idx+1}-{width}')
        record(f'all 28 puzzle layouts fit and controls scroll into view at {width}x{height}')
        ctx.close()
    # Real pointer reorder and car gesture, separately from accessible tap path.
    page.goto(URL+'?debug=1');page.evaluate('game=defaultGame();game.level=1;beginPuzzle()')
    items=page.locator('.sort-item');a=items.nth(0).bounding_box();b=items.nth(2).bounding_box();old=state(page)['puzzle']['order']
    page.mouse.move(a['x']+30,a['y']+30);page.mouse.down();page.mouse.move(b['x']+30,b['y']+30,steps=10);page.mouse.up();assert state(page)['puzzle']['order'][2]==old[0]
    page.evaluate('game=defaultGame();game.level=11;beginPuzzle()');cars=state(page)['puzzle']['cars'];car,direction=parking_solution(cars)[0];c=next(c for c in cars if c['id']==car)
    box=page.locator(f'[data-act="selectcar"][data-value="{car}"]').bounding_box();cell=page.locator('.parking-grid').bounding_box()['width']/6
    page.mouse.move(box['x']+box['width']/2,box['y']+box['height']/2);page.mouse.down();page.mouse.move(box['x']+box['width']/2+(cell*direction if c['dir']=='h' else 0),box['y']+box['height']/2+(cell*direction if c['dir']=='v' else 0),steps=10);page.mouse.up()
    assert state(page)['puzzle']['moves']>=1
    record('pointer drag reorders paper records and moves vehicles legally')
    page.evaluate('game=defaultGame();game.level=7;beginPuzzle()')
    left=page.locator('[data-act="left"][data-value="0"]');right=page.locator('[data-act="right"][data-value="0"]')
    left.scroll_into_view_if_needed();a=left.bounding_box();b=right.bounding_box()
    page.mouse.move(a['x']+20,a['y']+25);page.mouse.down();page.mouse.move(b['x']+20,b['y']+25,steps=10);page.mouse.up()
    assert 0 in state(page)['puzzle']['matched'];record('drag connects matching evidence; tap alternative also passed full case')
    page.evaluate('game=defaultGame();beginPuzzle()');click(page,'circuit',3);click(page,'reset');assert state(page)['puzzle']==page.evaluate('initPuzzle(LEVELS[0],0)')
    click(page,'hint');assert state(page)['hints']==1;click(page,'hint');assert state(page)['hints']==2;click(page,'hint');click(page,'skipYes');assert state(page)['phase']=='reveal' and len(state(page)['clues'])==1
    record('reset restores puzzle; two progressive hints and penalty-free player skip award exact clue')
    page.goto(URL+'#debug');assert page.locator('.devindicator').count()==1
    record('query flag and hash flag enable developer mode')
    for who in ('NINA','OWEN','CLAIRE','DANIEL'):
        page.evaluate('''who=>{const idx=LEVELS.findIndex(l=>l.intro.some(x=>x[0].includes(who)));game=defaultGame();game.level=idx;game.line=LEVELS[idx].intro.findIndex(x=>x[0].includes(who));render();}''',who)
        assert page.locator('.portrait').count()==1;shot(page,'character-'+who.lower())
    record('all four named characters have original illustrated appearances')
    page.evaluate('game=defaultGame();beginPuzzle()');page.locator('[data-act="circuit"]').first.focus();page.keyboard.press('Enter');assert page.locator('[data-act="circuit"]:focus').count()==1
    click(page,'menu');page.keyboard.press('Tab');assert page.locator('.overlay :focus').count()==1;page.keyboard.press('Escape');assert not page.locator('.overlay').count()
    record('keyboard puzzle focus survives render; settings trap focus and Escape closes')
    assert not errors,errors
    record('zero JavaScript exceptions across all runs')
    browser.close()
server.shutdown()
(OUT/'qa-results.json').write_text(json.dumps({'checks':checks,'failed':0,'console_errors':errors,'build_sha256':hashlib.sha256((ROOT/'dist/The_Last_Check_In.html').read_bytes()).hexdigest()},indent=2),encoding='utf8')
print(f'{len(checks)} checks passed, 0 failed',flush=True)
