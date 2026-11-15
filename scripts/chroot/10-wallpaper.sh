#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf '[INFO] %s\n' "$*"
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/wallpapers"
TARGET_DIR="/usr/share/backgrounds/sbeamos"

log "Installing SbeamOS wallpapers..."
install -d -m 0755 "$TARGET_DIR" /usr/share/gnome-background-properties

# The WIP12 image files are intentionally excluded from Git until their
# redistribution terms are confirmed. Generate original branded fallbacks
# when a checkout/build host does not provide those optional assets.
if [[ -d "$SOURCE_DIR" ]] && compgen -G "$SOURCE_DIR/*.png" >/dev/null; then
  install -m 0644 "$SOURCE_DIR"/*.png "$TARGET_DIR/"
else
  log "Bundled wallpaper assets are unavailable; using generated SbeamOS fallback wallpapers."
fi

# Ensure the two files referenced by the GNOME light/dark defaults always
# exist, even when the optional third-party wallpaper pack is not present.
python3 - "$TARGET_DIR" <<'PYGEN'
import struct
import sys
import zlib
from pathlib import Path

out = Path(sys.argv[1])
width, height = 1920, 1080

def chunk(kind, data):
    return (struct.pack('>I', len(data)) + kind + data
            + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff))

def make_png(path, top, bottom):
    rows = []
    for y in range(height):
        t = y / (height - 1)
        row = bytearray([0])
        for x in range(width):
            glow = max(0.0, 1.0 - (((x / width - 0.72) ** 2
                                   + (y / height - 0.18) ** 2) ** 0.5) / 0.9)
            for a, b in zip(top, bottom):
                row.append(max(0, min(255, int(a * (1 - t) + b * t + glow * 10))))
        rows.append(bytes(row))
    png = (b'\x89PNG\r\n\x1a\n'
           + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0))
           + chunk(b'IDAT', zlib.compress(b''.join(rows), 6))
           + chunk(b'IEND', b''))
    path.write_bytes(png)

for mode, top, bottom in (
    ('LM', (34, 74, 112), (10, 20, 38)),
    ('DM', (20, 34, 54), (5, 9, 18)),
):
    path = out / f'WP12-{mode}.png'
    if not path.exists() or path.stat().st_size == 0:
        make_png(path, top, bottom)
PYGEN

cat > "$TARGET_DIR/SOURCE.txt" <<'SOURCE'
SbeamOS wallpaper assets.

If WIP12 assets were supplied in scripts/chroot/wallpapers, they were copied
from the Microsoft Design WIP12 collection:
https://microsoft.design/wp-content/uploads/2026/10/wip12-wallpaper.zip

Those third-party images remain subject to their copyright and redistribution
terms. If no assets were supplied, original SbeamOS fallback gradients were
generated during the build.
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
