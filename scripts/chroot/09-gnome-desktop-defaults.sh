#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf '[INFO] %s\n' "$*"
}

log "Configuring system-wide GNOME desktop defaults..."

# Give each user a writable dconf database followed by SbeamOS defaults.
install -d -m 0755 /etc/dconf/profile /etc/dconf/db/local.d

cat > /etc/dconf/profile/user <<'EOF'
user-db:user
system-db:local
EOF

cat > /etc/dconf/db/local.d/00-sbeamos-desktop <<'EOF'
[org/gnome/desktop/input-sources]
sources=[('xkb', 'us'), ('ibus', 'libpinyin')]
current=0

[org/gnome/desktop/wm/preferences]
button-layout=':minimize,maximize,close'

[org/gnome/shell]
enabled-extensions=['ding@rastersoft.com', 'ubuntu-dock@ubuntu.com', 'ubuntu-appindicators@ubuntu.com']

[org/gnome/shell/extensions/dash-to-dock]
dock-position='BOTTOM'
dock-fixed=true
intellihide=true
intellihide-mode='MAXIMIZED_WINDOWS'
autohide=true
extend-height=false
dash-max-icon-size=44
show-trash=true
show-mounts=true

[org/gnome/shell/extensions/ding]
icon-size='standard'
show-home=true
show-trash=true
show-volumes=true
show-network-volumes=false
start-corner='top-left'

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

log "GNOME desktop defaults configured."
