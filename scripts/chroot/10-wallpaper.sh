#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf '[INFO] %s\n' "$*"
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/wallpapers"
TARGET_DIR="/usr/share/backgrounds/sbeamos"

log "Installing bundled SbeamOS wallpapers..."

[[ -d "$SOURCE_DIR" ]] || {
  printf '[ERROR] Bundled wallpaper directory is missing: %s\n' "$SOURCE_DIR" >&2
  exit 1
}
compgen -G "$SOURCE_DIR/*.png" >/dev/null || {
  printf '[ERROR] No bundled wallpaper images were found.\n' >&2
  exit 1
}

install -d -m 0755 "$TARGET_DIR" /usr/share/gnome-background-properties
install -m 0644 "$SOURCE_DIR"/*.png "$TARGET_DIR/"

cat > "$TARGET_DIR/SOURCE.txt" <<'SOURCE'
Wallpaper collection: WIP12
Original source: https://microsoft.design/wp-content/uploads/2026/10/wip12-wallpaper.zip

The wallpaper images remain the property of their respective copyright holder.
Check the source website's terms and obtain any required permission before
redistributing SbeamOS images or ISO files containing this collection.
SOURCE

log "Registering bundled wallpapers in GNOME Background settings..."
{
  printf '<?xml version="1.0" encoding="UTF-8"?>\n'
  printf '<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">\n'
  printf '<wallpapers>\n'
  for image in "$TARGET_DIR"/*.png; do
    filename="$(basename -- "$image")"
    printf '  <wallpaper deleted="false">\n'
    printf '    <name>SbeamOS - %s</name>\n' "${filename%.png}"
    printf '    <filename>%s</filename>\n' "$image"
    printf '    <options>zoom</options>\n'
    printf '    <shade_type>solid</shade_type>\n'
    printf '    <pcolor>#101827</pcolor>\n'
    printf '    <scolor>#101827</scolor>\n'
    printf '  </wallpaper>\n'
  done
  printf '</wallpapers>\n'
} > /usr/share/gnome-background-properties/sbeamos.xml

dconf update
log "Bundled wallpaper collection installed successfully."
