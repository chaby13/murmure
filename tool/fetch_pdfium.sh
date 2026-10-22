#!/usr/bin/env bash
# Télécharge PDFium pour lancer les tests sur un ordinateur Linux x64.
# Sur Android et iOS, pdfrx l'intègre automatiquement à la compilation.
# Usage : tool/fetch_pdfium.sh && PDFIUM_PATH=.pdfium/lib/libpdfium.so flutter test
set -euo pipefail
release='chromium%2F7811' # même version que pdfium_dart
mkdir -p .pdfium
curl -sSL "https://github.com/bblanchon/pdfium-binaries/releases/download/$release/pdfium-linux-x64.tgz" \
  | tar xz -C .pdfium
echo "PDFium prêt : .pdfium/lib/libpdfium.so"
