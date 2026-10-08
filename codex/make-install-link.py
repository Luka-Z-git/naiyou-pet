#!/usr/bin/env python3
"""Generate the documented Codex pet deep link after publishing a public GitHub repository."""
import argparse,json,re
from pathlib import Path
from urllib.parse import urlparse,urlencode,quote
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('repository',help='owner/repository or an https://github.com/owner/repository URL')
p.add_argument('--ref',default='main',help='Git branch, tag, or commit')
p.add_argument('--image-path',default='codex/pet/spritesheet.png',help='Path relative to the GitHub repository root')
args=p.parse_args()
slug=args.repository.strip()
if slug.startswith('https://'):
    u=urlparse(slug)
    if u.hostname!='github.com' or u.query or u.fragment:p.error('Expected a GitHub repository URL')
    slug=u.path.strip('/').removesuffix('.git')
if not re.fullmatch(r'[\w.-]+/[\w.-]+',slug):p.error('Expected owner/repository')
if not args.ref or args.image_path.startswith('/') or '..' in args.image_path.split('/'):p.error('Invalid branch or image path')
pet=json.loads((Path(__file__).parent/'pet/pet.json').read_text(encoding='utf-8'))
image='https://raw.githubusercontent.com/'+slug+'/'+quote(args.ref,safe='')+'/'+quote(args.image_path,safe='/')
query={'name':pet['displayName'],'description':pet['description'],'imageUrl':image,'spriteVersionNumber':2}
print('codex://pets/install?'+urlencode(query))

