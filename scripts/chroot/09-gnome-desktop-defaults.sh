#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf '[INFO] %s\n' "$*"
}


# Configure the desktop with Ubuntu's stock Yaru appearance.
# Keep only Ubuntu Dock and DING; remove assets left by older SbeamOS themes.
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

log "Removing obsolete SbeamOS theme assets and extensions..."
rm -rf /usr/share/themes/SbeamOS /usr/share/icons/SbeamOS \
  /usr/share/themes/SbeamOS-Light-blue /usr/share/themes/SbeamOS-Light-blue-hdpi \
  /usr/share/themes/SbeamOS-Light-blue-xhdpi \
  /usr/share/icons/SbeamOS-blue /usr/share/icons/SbeamOS-blue-dark \
  /usr/share/icons/SbeamOS-blue-light \
  /usr/share/gnome-shell/extensions/kiwimenu@kemma \
  /usr/share/gnome-shell/extensions/blur-my-shell@aunetx \
  /usr/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com \
  /etc/skel/.config/gtk-4.0/gtk.css
if dpkg-query -W -f='${Status}' gnome-shell-extension-user-theme 2>/dev/null | grep -q 'install ok installed'; then
  apt-get purge --yes gnome-shell-extension-user-theme
fi

log "Compiling the system dconf database..."
dconf update

log "Default Yaru theme, Ubuntu Dock, DING and US keyboard configured."
