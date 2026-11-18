#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf '[INFO] %s\n' "$*"
}


# Configure the SbeamOS desktop using native GNOME settings and
# extensions. Ubuntu Dock and DING remain responsible for the bottom Dock
# and desktop icons; Kiwi Menu and Blur my Shell provide the Aurora look.
install -d -m 0755 /etc/dconf/profile /etc/dconf/db/local.d

cat > /etc/dconf/profile/user <<'EOF'
user-db:user
system-db:local
EOF

cat > /etc/dconf/db/local.d/00-sbeamos-desktop <<'EOF'
[org/gnome/shell]
enabled-extensions=['ubuntu-dock@ubuntu.com', 'ding@rastersoft.com']

[org/gnome/shell/extensions/dash-to-dock]
dock-position='BOTTOM'
dock-fixed=true
autohide=false
intellihide=false
extend-height=false
icon-size-fixed=true
dash-max-icon-size=48

[org/gnome/shell/extensions/ding]
show-home=true
show-trash=true
show-volumes=true

[org/gnome/desktop/input-sources]
sources=[('xkb', 'us')]
current=0

[org/gnome/desktop/wm/preferences]
button-layout='close,minimize,maximize:'

[org/gnome/desktop/interface]
gtk-theme='Yaru'
icon-theme='Yaru'
color-scheme='prefer-light'

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

log "Aurora appearance, Liquid Glass effects, macOS menu, Dock and desktop icons enabled; US keyboard only."
