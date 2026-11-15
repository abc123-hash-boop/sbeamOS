#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf '[INFO] %s\n' "$*"
}

FONT_DIR="/usr/share/fonts/opentype/noto"

log "Reducing the Noto CJK font footprint..."

# SbeamOS only needs a Chinese fallback for its Latin-only Sbeam UI font.
# Keep Noto Sans CJK regular and bold for normal and emphasized text.
# Remove the Noto Serif CJK family to avoid shipping an unused second family.
for font in \
  "$FONT_DIR/NotoSerifCJK-Regular.ttc" \
  "$FONT_DIR/NotoSerifCJK-Bold.ttc"; do
  if [[ -f "$font" ]]; then
    rm -f -- "$font"
    log "Removed $(basename -- "$font")"
  fi
done

fc-cache --force "$FONT_DIR"

log "Noto CJK font trimming completed. Sans regular/bold remain available as Chinese fallback."
