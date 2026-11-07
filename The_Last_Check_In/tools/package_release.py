"""Package the verified build, source and evidence without test dependencies."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from hashlib import sha256
from html import escape
import json
root=Path(__file__).resolve().parents[1]
results=json.loads((root/'artifacts/qa-results.json').read_text(encoding='utf8'))
digest=sha256((root/'dist/The_Last_Check_In.html').read_bytes()).hexdigest()
assert results['failed']==0 and results['build_sha256']==digest, 'Run production_qa.py against the current build before packaging'
assert sha256((root/'source/story.js').read_bytes()).hexdigest()=='1fba0f43000801c60f00f4b881771fd348077fa39a044e23e93d03da64996228', 'Canonical story changed'
report=f'''# Verified production results — 7 November 2026

Final build SHA-256: `{digest}`.

`tests/smoke_playwright.py`: passed normal/debug checks at 360×780 and 412×915.

`tests/full_case_debug.py`: passed all 28 developer skips, exact clue-title checks, four chapters and the complete ending.

`tests/production_qa.py`: **{len(results['checks'])} checks passed, 0 failed; zero JavaScript exceptions**.

'''+''.join('- '+x+'\n' for x in results['checks'])+'''
## Evidence and reproducibility

See `artifacts/qa-results.json` for the machine-readable result, and `artifacts/index.html` for the screenshot gallery. The original handoff smoke/full-case tests passed before changes. `source/story.js` is byte-for-byte identical to the supplied archive (SHA-256 `1fba0f43000801c60f00f4b881771fd348077fa39a044e23e93d03da64996228`).

Normal-play solvers calculate legal moves externally and click the real UI; they never overwrite a puzzle with a solved state. Separate save-recovery, layout and developer fixtures intentionally select states to inspect those paths. The legal-input walkthrough disables browser-context network access after loading the local HTML. Desktop is checked at 1280×900; all three phone sizes inspect every stage and verify scroll access to controls, with header buttons remaining inside the viewport.

The standalone HTML is built only from local source. No runtime third-party dependencies or media requests are required. Screenshots settle finite animations for legible captures. The preview server's HTTP response was verified as 200.

## Acceptance limits

Automated Chromium touch emulation is not physical Android/iOS acceptance. Real-device audio balance, speaker/headphone listening, sustained performance, screen-reader usability and player judgement of art/game feel remain unverified. Runtime art and audio are original vector/procedural work; there is no painted raster pack, recorded soundtrack, voice acting, APK or installable PWA. The source retains background-tab audio suspension, but real-device audio interruption/recovery still needs hands-on testing.
'''
(root/'QA_RESULTS.md').write_text(report,encoding='utf8')
shots=sorted(p for p in (root/'artifacts').glob('*.png') if p.name!='title-inspect.png')
gallery='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The Last Check-In — screenshots</title><style>body{background:#0c222b;color:#eee5d3;font:16px system-ui;margin:24px}main{display:flex;flex-wrap:wrap;gap:24px}figure{margin:0;max-width:390px}img{width:100%;height:auto}figcaption{padding:12px 0}</style><h1>The Last Check-In</h1><p>Verified production screenshots. Phone images use Chromium touch emulation.</p><main>'+''.join(f'<figure><a href="{escape(p.name)}"><img loading="lazy" src="{escape(p.name)}" alt="{escape(p.stem)}"></a><figcaption>{escape(p.stem)}</figcaption></figure>' for p in shots)+'</main></html>'
(root/'artifacts/index.html').write_text(gallery,encoding='utf8')
release=root/'release';release.mkdir(exist_ok=True)
dest=release/'The_Last_Check_In_Polished.zip'
with ZipFile(dest,'w',ZIP_DEFLATED) as z:
    for p in sorted(root.rglob('*')):
        if p.is_file() and not any(part in ('release','__pycache__','.git') for part in p.relative_to(root).parts) and p.suffix!='.log' and p.name!='title-inspect.png':
            z.write(p,Path('The_Last_Check_In')/p.relative_to(root))
print(f'Packaged {dest} ({dest.stat().st_size:,} bytes), {len(shots)} screenshots')
