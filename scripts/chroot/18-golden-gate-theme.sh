#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

log() {
  printf '[INFO] %s\n' "$*"
}

WORK_DIR="/tmp/sbeamos-golden-gate"
GTK_REPO="$WORK_DIR/MacTahoe-gtk-theme"
ICON_REPO="$WORK_DIR/MacTahoe-icon-theme"
BLUR_REPO="$WORK_DIR/blur-my-shell"
KIWI_REPO="$WORK_DIR/kiwi-menu"

# Pin upstream sources so the same SbeamOS revision always builds from the
# same theme and extension revisions.
clone_pinned() {
  local url="$1" commit="$2" target="$3"
  rm -rf "$target"
  install -d -m 0755 "$target"
  git -C "$target" init --quiet
  git -C "$target" remote add origin "$url"
  git -C "$target" fetch --quiet --depth=1 origin "$commit"
  git -C "$target" checkout --quiet --detach FETCH_HEAD
}

log "Installing Golden Gate desktop theme dependencies..."
apt-get install --yes --no-install-recommends \
  git \
  make \
  unzip \
  gettext \
  sassc \
  libglib2.0-dev-bin \
  libxml2-utils \
  imagemagick \
  gnome-shell-extension-user-theme \
  gnome-shell-extension-manager \
  gnome-tweaks

log "Fetching pinned MacTahoe GTK and icon themes..."
install -d -m 0755 "$WORK_DIR"
clone_pinned \
  https://github.com/vinceliuice/MacTahoe-gtk-theme.git \
  1e45e19f510edb8cde18fa84d6cd5319f60b086b "$GTK_REPO"
clone_pinned \
  https://github.com/vinceliuice/MacTahoe-icon-theme.git \
  839848b9a8a38a92a6936e30c4abe35cc6f2546d "$ICON_REPO"

log "Building the SbeamOS light-blue GTK and GNOME Shell theme..."
"$GTK_REPO/install.sh" \
  --silent-mode \
  --dest /usr/share/themes \
  --name SbeamOS \
  --color light \
  --theme blue \
  --opacity normal \
  --alt normal \
  --blur \
  --round \
  --shell \
  -icon apple \
  -panelopacity 30

log "Generating the matching libadwaita GTK 4 theme for new Live users..."
# MacTahoe's libadwaita helper intentionally refuses to run as root. Build its
# per-user GTK 4 config in an isolated temporary home, then seed /etc/skel.
GTK4_HOME="$WORK_DIR/gtk4-home"
install -d -m 0755 "$GTK4_HOME"
useradd --system --user-group --home-dir "$GTK4_HOME" --shell /usr/sbin/nologin sbeamos-theme-build
chown -R sbeamos-theme-build:sbeamos-theme-build "$GTK4_HOME" "$GTK_REPO"
runuser -u sbeamos-theme-build -- env HOME="$GTK4_HOME" SUDO_USER=sbeamos-theme-build \
  "$GTK_REPO/install.sh" \
  --dest "$GTK4_HOME/themes" \
  --name SbeamOS \
  --color light \
  --theme blue \
  --libadwaita
install -d -m 0755 /etc/skel/.config
rm -rf /etc/skel/.config/gtk-4.0
cp -a "$GTK4_HOME/.config/gtk-4.0" /etc/skel/.config/gtk-4.0
# The upstream helper creates absolute symlinks inside its temporary HOME.
# Rewrite them to relative links before deleting that build user's home.
ln -sfn gtk-Light.css /etc/skel/.config/gtk-4.0/gtk.css
ln -sfn gtk-Dark.css /etc/skel/.config/gtk-4.0/gtk-dark.css
chown -R root:root /etc/skel/.config/gtk-4.0
userdel --remove sbeamos-theme-build
groupdel sbeamos-theme-build

log "Installing the matching SbeamOS icon and cursor assets..."
"$ICON_REPO/install.sh" \
  --dest /usr/share/icons \
  --name SbeamOS \
  --theme blue

log "Installing Blur my Shell for the Liquid Glass panel and dock..."
clone_pinned \
  https://github.com/aunetx/blur-my-shell.git \
  3556b496cfdcd3303f9d56f8c828d94c39965660 "$BLUR_REPO"
make -C "$BLUR_REPO" build
BLUR_EXTENSION_DIR="/usr/share/gnome-shell/extensions/blur-my-shell@aunetx"
install -d -m 0755 "$BLUR_EXTENSION_DIR"
unzip -oq "$BLUR_REPO/build/blur-my-shell@aunetx.shell-extension.zip" -d "$BLUR_EXTENSION_DIR"

log "Installing the macOS-style Kiwi menu for GNOME..."
clone_pinned \
  https://github.com/kem-a/kiwi-menu.git \
  9cb445430b30f182fb2c7ec32cc4c027bc792c0e "$KIWI_REPO"
KIWI_EXTENSION_DIR="/usr/share/gnome-shell/extensions/kiwimenu@kemma"
install -d -m 0755 "$KIWI_EXTENSION_DIR"
cp -a "$KIWI_REPO"/. "$KIWI_EXTENSION_DIR"/
rm -rf "$KIWI_EXTENSION_DIR/.git"

log "Installing upstream license notices and pinned source manifest..."
LICENSE_DIR="/usr/share/doc/sbeamos-theme-licenses"
install -d -m 0755 "$LICENSE_DIR"
install -m 0644 "$GTK_REPO/COPYING" "$LICENSE_DIR/MacTahoe-GTK-MIT.txt"
install -m 0644 "$ICON_REPO/COPYING" "$LICENSE_DIR/MacTahoe-Icons-GPL-3.0.txt"
install -m 0644 "$BLUR_REPO/LICENSE" "$LICENSE_DIR/Blur-my-Shell-GPL-3.0.txt"
install -m 0644 "$KIWI_REPO/LICENSE" "$LICENSE_DIR/Kiwi-Menu-LICENSE.txt"
cat > "$LICENSE_DIR/SOURCES.txt" <<'EOF'
SbeamOS Golden Gate desktop appearance components

MacTahoe GTK theme
  https://github.com/vinceliuice/MacTahoe-gtk-theme
  Commit: 1e45e19f510edb8cde18fa84d6cd5319f60b086b

MacTahoe icon and cursor theme
  https://github.com/vinceliuice/MacTahoe-icon-theme
  Commit: 839848b9a8a38a92a6936e30c4abe35cc6f2546d

Blur my Shell (Liquid Glass effects)
  https://github.com/aunetx/blur-my-shell
  Commit: 3556b496cfdcd3303f9d56f8c828d94c39965660

Kiwi Menu (macOS-style top-bar menu)
  https://github.com/kem-a/kiwi-menu
  Commit: 9cb445430b30f182fb2c7ec32cc4c027bc792c0e
EOF

log "Compiling GNOME extension settings schemas..."
glib-compile-schemas "$BLUR_EXTENSION_DIR/schemas"
glib-compile-schemas "$KIWI_EXTENSION_DIR/schemas"
glib-compile-schemas /usr/share/glib-2.0/schemas

rm -rf "$WORK_DIR"

log "Removing temporary theme-build toolchain..."
apt-get purge --yes \
  sassc \
  libglib2.0-dev-bin \
  libxml2-utils \
  imagemagick \
  gettext \
  make

log "Golden Gate theme, icons, Liquid Glass effects and menu installed."
