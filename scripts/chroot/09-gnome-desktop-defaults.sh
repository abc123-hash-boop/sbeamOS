#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf '[INFO] %s\n' "$*"
}

log "Applying conservative GNOME defaults for the Live desktop..."

# Start with an unmodified GNOME Shell session. Ubuntu's Dock, DING and
# AppIndicator extensions are intentionally disabled while stabilizing the
# first boot; they can be enabled individually after the base session is
# proven stable.
install -d -m 0755 /etc/dconf/profile /etc/dconf/db/local.d

cat > /etc/dconf/profile/user <<'EOF'
user-db:user
system-db:local
EOF

cat > /etc/dconf/db/local.d/00-sbeamos-desktop <<'EOF'
[org/gnome/shell]
enabled-extensions=[]

[org/gnome/desktop/input-sources]
sources=[('xkb', 'us')]
current=0

[org/gnome/desktop/wm/preferences]
button-layout=':minimize,maximize,close'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/sbeamos/WP12-LM.png'
picture-uri-dark='file:///usr/share/backgrounds/sbeamos/WP12-DM.png'
picture-options='zoom'
color-shading-type='solid'
primary-color='#101827'
secondary-color='#101827'
EOF

log "Compiling the system dconf database..."
dconf update

log "Conservative GNOME defaults configured (extensions and custom input engines disabled)."
