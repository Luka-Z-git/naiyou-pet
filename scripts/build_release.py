#!/usr/bin/env python3
"""Build portable pet packages from this repository using only the Python standard library."""
import argparse,base64,hashlib,json,re,struct,zipfile
from pathlib import Path

root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--outdir',type=Path,default=root/'dist')
out=p.parse_args().outdir.resolve();out.mkdir(parents=True,exist_ok=True)
sprite=root/'dsh/plugin/naiyou-spritesheet.png'
data=sprite.read_bytes()
assert data[:8]==b'\x89PNG\r\n\x1a\n' and struct.unpack('>II',data[16:24])==(1536,2288)
assert data==(root/'codex/pet/spritesheet.png').read_bytes()
pet=json.loads((root/'codex/pet/pet.json').read_text(encoding='utf-8'))
assert pet['spriteVersionNumber']==2 and pet['spritesheetPath']=='spritesheet.png'
template=(root/'dsh/client.template.js').read_text(encoding='utf-8')
template=template.replace("window.location.protocol === 'dsh-app:'", "window.location.protocol === 'dsh-app:' && /Windows/i.test(navigator.userAgent)")
assert template.count('__SPRITESHEET_DATA_URL__')==1
(root/'dsh/plugin/client.js').write_text(template.replace('__SPRITESHEET_DATA_URL__','data:image/png;base64,'+base64.b64encode(data).decode()),encoding='utf-8')
manifest=json.loads((root/'dsh/plugin/package.json').read_text(encoding='utf-8'))
assert manifest['name']=='@local/dsh-naiyou-pet'
for file in manifest['files']:
    assert '/' not in file and '\\' not in file and (root/'dsh/plugin'/file).is_file(),file

def digest(data):return hashlib.sha256(data).hexdigest()
def files_under(folder):
    return sorted(f for f in (root/folder).rglob('*') if f.is_file() and '__pycache__' not in f.parts and f.name!='CHECKSUMS.sha256')
def check_shareable(file):
    assert file.suffix.lower() not in {'.log','.db','.sqlite','.jsonl'},file
    assert file.name not in {'.env','config.toml','cordis.yml','pnpm-lock.yaml'},file
    if file.suffix.lower() in {'.js','.mjs','.py','.json','.yml','.html','.md','.ps1','.cmd','.sh',''}:
        text=file.read_text(encoding='utf-8-sig')
        for pattern in (r'[A-Z]:[/\\]Users[/\\][^\s"\x27]+',r'\b(?:pet|sharepet)_[0-9a-f]{12,}',r'\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}'):
            assert not re.search(pattern,text),f'{file}: personal data or credential marker'

def write_zip(name,prefix,entries):
    payload=dict(entries)
    checksums=''.join(digest(content)+'  '+path+'\n' for path,content in sorted(payload.items()))
    payload['CHECKSUMS.sha256']=checksums.encode('utf-8')
    target=out/name
    with zipfile.ZipFile(target,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
        for path,content in sorted(payload.items()):
            info=zipfile.ZipInfo(prefix+'/'+path,date_time=(2026,10,8,0,0,0))
            info.compress_type=zipfile.ZIP_DEFLATED
            info.external_attr=(0o100755 if path.endswith('.sh') else 0o100644)<<16
            archive.writestr(info,content)
    with zipfile.ZipFile(target) as archive:assert archive.testzip() is None
    return target

common=[(name,(root/name).read_bytes()) for name in ('LICENSE','ASSETS.md')]
releases=[]
for platform,version in [('codex','1.0.0'),('dsh',manifest['version'])]:
    entries=[]
    for f in files_under(platform):
        check_shareable(f);entries.append((f.relative_to(root/platform).as_posix(),f.read_bytes()))
    entries.extend(common)
    releases.append(write_zip(f'naiyou-{platform}-v{version}.zip',f'naiyou-{platform}-v{version}',entries))
source_files=[root/name for name in ('README.md','LICENSE','ASSETS.md','VALIDATION.md','.gitignore')]
for folder in ('codex','dsh','scripts','tests','.github'):source_files+=files_under(folder)
source=[]
for f in sorted(set(source_files)):
    check_shareable(f);source.append((f.relative_to(root).as_posix(),f.read_bytes()))
releases.append(write_zip(f'naiyou-github-source-v{manifest["version"]}.zip','naiyou-pet',source))
(out/'SHA256SUMS.txt').write_text(''.join(digest(f.read_bytes())+'  '+f.name+'\n' for f in releases),encoding='utf-8')
for f in releases:print(f'{f.name}: {f.stat().st_size:,} bytes')
print('PASS: sprite geometry, identical assets, full package file list, archive CRC, and personal-data scan')
