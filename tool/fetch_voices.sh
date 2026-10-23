#!/usr/bin/env bash
# Télécharge les voix naturelles embarquées dans l'application (Piper,
# quantifiées int8, via les modèles publiés par sherpa-onnx) :
#   - Siwis, français (CC-BY 4.0)
#   - Alba, anglais britannique (CC-BY 4.0)
# et les données de prononciation espeak-ng réduites au français et à
# l'anglais. L'appli ne télécharge jamais rien elle-même.
# Usage : tool/fetch_voices.sh
set -euo pipefail
out=assets/voices
base=https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models
voices=(fr_FR-siwis-medium en_GB-alba-medium)
if [ -s "$out/espeak-ng-data.zip" ] && [ -s "$out/en_GB-alba-medium.onnx" ]; then
  echo "Voix déjà présentes dans $out"
  exit 0
fi
mkdir -p "$out"
tmp=$(mktemp -d)
py=$(command -v python3 || command -v python)
for v in "${voices[@]}"; do
  curl -sSL --retry 4 -o "$tmp/$v.tar.bz2" "$base/vits-piper-$v-int8.tar.bz2"
  "$py" -c "import sys, tarfile; tarfile.open(sys.argv[1]).extractall(sys.argv[2])" \
    "$tmp/$v.tar.bz2" "$tmp"
  dir="$tmp/vits-piper-$v-int8"
  cp "$dir/$v.onnx" "$out/$v.onnx"
  cp "$dir/tokens.txt" "$out/$v.tokens.txt"
  cp "$dir/MODEL_CARD" "$out/$v.MODEL_CARD.txt"
  grep -qi "CC-BY 4.0\|creativecommons.org/licenses/by/4.0" "$dir/MODEL_CARD" \
    || { echo "Licence inattendue pour $v" >&2; exit 1; }
done
# Données espeak-ng : seulement ce qui sert au français et à l'anglais.
"$py" - "$tmp/vits-piper-${voices[0]}-int8/espeak-ng-data" "$out/espeak-ng-data.zip" <<'PY'
import os, sys, zipfile
src, dest = sys.argv[1], sys.argv[2]
keep_files = {'phondata', 'phondata-manifest', 'phonindex', 'phontab',
              'intonations', 'fr_dict', 'en_dict'}
with zipfile.ZipFile(dest, 'w', zipfile.ZIP_DEFLATED) as z:
    for root, _, files in os.walk(src):
        rel = os.path.relpath(root, src)
        top = rel.split(os.sep)[0]
        for f in files:
            if rel == '.' and f not in keep_files:
                continue
            if rel != '.' and top not in ('lang', 'voices'):
                continue
            path = os.path.join(root, f)
            z.write(path, os.path.join('espeak-ng-data', os.path.relpath(path, src)))
PY
rm -rf "$tmp"
ls -la "$out"
