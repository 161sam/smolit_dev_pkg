#!/usr/bin/env bash
# clean-up.sh — verschiebt alle *.bak* Dateien nach archive/
# Nutzung: ./clean-up.sh [-n] [-t <zielordner>]
#   -n, --dry-run     Nur anzeigen, was passieren würde
#   -t, --target DIR  Zielordner (Default: archive)

set -Eeuo pipefail
shopt -s nullglob dotglob

DRY_RUN=0
TARGET="archive"

usage() {
  echo "Usage: $0 [-n|--dry-run] [-t|--target <dir>]"
  exit "${1:-0}"
}

# --- Optionen parsen ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1; shift ;;
    -t|--target)  [[ $# -ge 2 ]] || usage 1; TARGET="$2"; shift 2 ;;
    -h|--help)    usage 0 ;;
    *)            echo "Unbekannte Option: $1"; usage 1 ;;
  esac
done

# --- Zielordner anlegen ---
if [[ $DRY_RUN -eq 0 ]]; then
  mkdir -p "$TARGET"
fi

# --- Kandidaten finden (alles außer bereits im TARGET) ---
mapfile -d '' FILES < <(find . \
  -path "./$TARGET/*" -prune -o \
  -type f -name '*.bak*' -print0)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "Nichts zu tun: keine *.bak* Dateien gefunden."
  exit 0
fi

MOVED=0
for SRC in "${FILES[@]}"; do
  # Pfad relativ ohne führendes ./
  REL="${SRC#./}"
  DEST="$TARGET/$REL"
  DEST_DIR="$(dirname "$DEST")"

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] mv -- \"$SRC\" \"$DEST\""
  else
    mkdir -p "$DEST_DIR"
    mv -- "$SRC" "$DEST"
    echo "moved: $SRC -> $DEST"
    ((MOVED+=1))
  fi
done

if [[ $DRY_RUN -eq 1 ]]; then
  echo "Dry-run beendet. Betroffene Dateien: ${#FILES[@]}"
else
  echo "Fertig. Verschoben: $MOVED Datei(en) nach '$TARGET/'."
fi

