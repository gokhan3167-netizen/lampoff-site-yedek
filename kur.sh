#!/bin/bash
# LampOff yedek + deneme sitesi kurulumu.
#   kök (/)      = lampoff-site › main  (canlı sitenin kopyası — lampofflighting.com çökerse buraya geçilir)
#   /deneme/     = lampoff-site › deneme (yayına almadan önce denenen sürüm)
# Arama motorlarına kapalı: her sayfaya noindex, robots.txt Disallow. CNAME alınmaz (alan adı canlı sitede kalır).
# Kullanım: bash kur.sh <çıkış klasörü>   (GitHub Actions her saat çalıştırır)
set -e
OUT="${1:-_site}"; BASE="/lampoff-site-yedek"; T=$(mktemp -d)
git clone -q --depth 1 -b main   https://github.com/gokhan3167-netizen/lampoff-site "$T/main"
git clone -q --depth 1 -b deneme https://github.com/gokhan3167-netizen/lampoff-site "$T/deneme"
rm -rf "$OUT"; mkdir -p "$OUT/deneme"
SM=$(git -C "$T/main" rev-parse --short HEAD); SD=$(git -C "$T/deneme" rev-parse --short HEAD)
for b in main deneme; do rm -rf "$T/$b/.git" "$T/$b/.github" "$T/$b/CNAME"; done
cp -a "$T/main/." "$OUT/"
cp -a "$T/deneme/." "$OUT/deneme/"
python3 - "$OUT" "$BASE" <<'PY'
import os,re,sys
out,base=sys.argv[1],sys.argv[2]
for root,_,files in os.walk(out):
  for f in files:
    if not f.endswith('.html'): continue
    p=os.path.join(root,f); s=open(p,encoding='utf-8').read()
    pre=base+('/deneme' if os.path.relpath(p,out).startswith('deneme'+os.sep) else '')
    # kökten başlayan bağlantılar alt klasöre göre düzeltilir (//… ve http… dokunulmaz)
    s=re.sub(r'(\s(?:href|src|action)=")/(?!/)',lambda m:m.group(1)+pre+'/',s)
    if 'name="robots"' not in s: s=s.replace('<head>','<head><meta name="robots" content="noindex,nofollow">',1)
    open(p,'w',encoding='utf-8').write(s)
open(os.path.join(out,'robots.txt'),'w').write('User-agent: *\nDisallow: /\n')
for sm in ['sitemap.xml','deneme/sitemap.xml']:
  q=os.path.join(out,sm)
  if os.path.exists(q): os.remove(q)
open(os.path.join(out,'.nojekyll'),'w').close()
PY
echo "tamam: $OUT (main $SM, deneme $SD)"
