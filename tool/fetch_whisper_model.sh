#!/usr/bin/env bash
# Télécharge le modèle de transcription embarqué dans l'application :
# Whisper « base » multilingue quantifié q5_1 (≈ 57 Mo, licence MIT,
# format whisper.cpp). Il est ensuite inclus dans l'APK et l'exe : l'appli
# ne télécharge jamais rien elle-même.
# Ajoute aussi le détecteur de parole Silero.
# Usage : tool/fetch_whisper_model.sh
set -euo pipefail
mkdir -p assets/models
# Détecteur de parole Silero (≈ 1 Mo, licence MIT) : retire les silences
# avant la transcription.
vad=assets/models/ggml-silero-v5.1.2.bin
if [ ! -s "$vad" ]; then
  curl -sSfL --retry 4 -o "$vad.part" \
    "https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v5.1.2.bin"
  vsize=$(wc -c < "$vad.part")
  if [ "$vsize" -lt 500000 ]; then
    echo "Détecteur de parole invalide (taille $vsize)." >&2
    rm -f "$vad.part"
    exit 1
  fi
  mv "$vad.part" "$vad"
fi
target=assets/models/ggml-base-q5_1.bin
if [ -s "$target" ]; then
  echo "Modèle déjà présent : $target"
  exit 0
fi
curl -sSL --retry 4 -o "$target.part" \
  "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base-q5_1.bin"
size=$(wc -c < "$target.part")
magic=$(head -c 4 "$target.part" | od -An -tx1 | tr -d ' \n')
# Fichier ggml (en-tête 0x67676d6c en petit-boutiste) d'au moins 50 Mo.
if [ "$magic" != "6c6d6767" ] || [ "$size" -lt 50000000 ]; then
  echo "Modèle invalide (taille $size, en-tête $magic)." >&2
  rm -f "$target.part"
  exit 1
fi
mv "$target.part" "$target"
echo "Modèle prêt : $target ($size octets, sha256 $(sha256sum "$target" | cut -c1-16)…)"
