#!/usr/bin/env python3
"""Rebuilds the self-contained offline HTML game from editable source files.
Usage: python tools/build_singlefile.py
No third-party Python packages required.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
template=(root/'source'/'template.html').read_text(encoding='utf-8')
css='\n'.join((root/'source'/n).read_text(encoding='utf-8') for n in ('style.css','polish.css'))
js='\n'.join((root/'source'/n).read_text(encoding='utf-8') for n in ('story.js','art.js','soundscape.js','engine.js','interaction.js'))
assert template.count('/* CSS_INSERT */')==1
assert template.count('/* JS_INSERT */')==1
out=template.replace('/* CSS_INSERT */',css).replace('/* JS_INSERT */',js)

# Embed painterly artwork into the single standalone HTML with no network requests.
import base64
assets={'EXTERIOR_TITLE':'exterior_title.webp','EXTERIOR':'exterior.webp','RECEPTION':'reception.webp','SECURITY':'security.webp','ROOM':'room.webp',
        'PORTRAIT_NINA':'portrait_nina.webp','PORTRAIT_CLAIRE':'portrait_claire.webp',
        'PORTRAIT_OWEN':'portrait_owen.webp','PORTRAIT_DANIEL':'portrait_daniel.webp'}
for token,filename in assets.items():
    value='data:image/webp;base64,'+base64.b64encode((root/'assets'/'art'/filename).read_bytes()).decode('ascii')
    assert out.count('__ART_'+token+'__')==1, token
    out=out.replace('__ART_'+token+'__', value)

dest=root/'dist'/'The_Last_Check_In.html'
dest.parent.mkdir(exist_ok=True)
dest.write_text(out,encoding='utf-8')
print(f'Built {dest} ({len(out):,} characters)')
