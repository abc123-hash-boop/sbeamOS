#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

log() { printf '[INFO] %s\n' "$*"; }
WORK_DIR=/tmp/sbeamos-theme-build
BLUR_REPO="$WORK_DIR/blur-my-shell"
KIWI_REPO="$WORK_DIR/kiwi-menu"
THEME_DIR=/usr/share/themes/SbeamOS
ICON_DIR=/usr/share/icons/SbeamOS

clone_pinned() {
  local url="$1" commit="$2" target="$3"
  rm -rf "$target"
  install -d -m 0755 "$target"
  git -C "$target" init --quiet
  git -C "$target" remote add origin "$url"
  git -C "$target" fetch --quiet --depth=1 origin "$commit"
  git -C "$target" checkout --quiet --detach FETCH_HEAD
}

log "Installing SbeamOS native theme build dependencies..."
apt-get install --yes --no-install-recommends git make unzip
install -d -m 0755 "$THEME_DIR/gtk-3.0" "$THEME_DIR/gnome-shell" \
  "$ICON_DIR/scalable/places" "$ICON_DIR/scalable/apps" "$ICON_DIR/scalable/status" \
  /etc/skel/.config/gtk-4.0 "$WORK_DIR"

log "Creating original SbeamOS GTK theme..."
cat > "$THEME_DIR/index.theme" <<'THEME'
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=SbeamOS
Comment=Original SbeamOS desktop theme
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=SbeamOS
MetacityTheme=SbeamOS
IconTheme=SbeamOS
CursorTheme=Adwaita
ButtonLayout=close,minimize,maximize:
THEME

cat > "$THEME_DIR/gtk-3.0/gtk.css" <<'GTK3'
/* SbeamOS — Aurora design system */
@define-color accent_color #2878e5;
@define-color accent_bg_color #2878e5;
@define-color accent_fg_color #ffffff;
@define-color window_bg_color #f4f7fc;
@define-color window_fg_color #17243a;
@define-color view_bg_color #ffffff;
@define-color view_fg_color #17243a;
@define-color headerbar_bg_color #f8faff;
@define-color headerbar_fg_color #17243a;
@define-color card_bg_color #ffffff;
@define-color popover_bg_color #ffffff;
@define-color popover_fg_color #17243a;
@define-color sidebar_bg_color #edf2fa;
@define-color borders rgba(37, 65, 105, 0.14);
@define-color theme_selected_bg_color #2878e5;
@define-color theme_selected_fg_color #ffffff;

* { -GtkWidget-focus-line-width: 0; -GtkWidget-focus-padding: 2; outline-color: alpha(#2878e5, 0.45); }
window, .background { background-color: #f4f7fc; color: #17243a; }
headerbar, .titlebar { min-height: 42px; padding: 5px 10px; color: #17243a; background: linear-gradient(to bottom, #ffffff, #f5f8fd); border: 0; border-bottom: 1px solid rgba(37,65,105,0.12); box-shadow: 0 1px 5px rgba(23,36,58,0.04); }
headerbar button, button { color: #243650; background: #ffffff; border: 1px solid rgba(37,65,105,0.14); border-radius: 9px; padding: 6px 11px; box-shadow: 0 1px 2px rgba(23,36,58,0.04); }
button:hover { background: #edf4ff; border-color: rgba(40,120,229,0.35); }
button:active, button:checked { color: #1457b5; background: #e2efff; border-color: rgba(40,120,229,0.45); }
button:disabled { color: #9aa8ba; background: #f1f4f8; }
entry, spinbutton, .linked entry { color: #17243a; background: #ffffff; border: 1px solid rgba(37,65,105,0.19); border-radius: 9px; padding: 7px 10px; }
entry:focus, spinbutton:focus { border-color: #2878e5; box-shadow: 0 0 0 3px alpha(#2878e5,0.16); }
textview, list, row, treeview.view, .view { color: #17243a; background: #ffffff; }
.sidebar, placessidebar, .navigation-sidebar { color: #30435f; background: #edf2fa; }
.sidebar row, placessidebar row { min-height: 34px; border-radius: 8px; margin: 2px 6px; }
.sidebar row:selected, placessidebar row:selected, row:selected { color: #124f9f; background: #dceaff; }
check, radio { color: #2878e5; }
progressbar progress, scale highlight { background: #2878e5; border-radius: 99px; }
progressbar trough, scale trough { background: #dce5f1; border-radius: 99px; }
scrollbar slider { background: alpha(#526985,0.32); border-radius: 99px; min-width: 6px; min-height: 6px; }
tooltip { color: #ffffff; background: #17243a; border: 1px solid alpha(#ffffff,0.12); border-radius: 8px; padding: 5px 8px; }
popover, menu { color: #17243a; background: #ffffff; border: 1px solid rgba(37,65,105,0.12); border-radius: 12px; box-shadow: 0 10px 32px rgba(18,35,60,0.14); }
GTK3

cat > "$THEME_DIR/gnome-shell/gnome-shell.css" <<'SHELL'
/* SbeamOS Aurora GNOME Shell theme */
stage { font-family: Cantarell, sans-serif; color: #17243a; }
#panel { background-color: rgba(16, 31, 52, 0.70); color: #f5f9ff; border-bottom: 1px solid rgba(255,255,255,0.14); font-weight: 600; }
#panel .panel-button { color: #f5f9ff; border-radius: 9px; margin: 3px 2px; padding: 0 9px; }
#panel .panel-button:hover, #panel .panel-button:active, #panel .panel-button:checked { background-color: rgba(112,174,255,0.24); }
#panel .panel-button .app-menu-icon { -st-icon-style: symbolic; }
.popup-menu-content { padding: 7px; border: 1px solid rgba(255,255,255,0.24); border-radius: 15px; background-color: rgba(245,249,255,0.94); color: #17243a; box-shadow: 0 12px 36px rgba(5,18,38,0.22); }
.popup-menu-item { color: #17243a; border-radius: 8px; padding: 8px 12px; }
.popup-menu-item:hover, .popup-menu-item:focus { color: #104f9f; background-color: rgba(40,120,229,0.13); }
.popup-separator-menu-item .popup-separator { background-color: rgba(37,65,105,0.14); }
.calendar, .datemenu-calendar-column { color: #17243a; }
.calendar .calendar-day { border-radius: 8px; }
.calendar .calendar-day:selected { color: #fff; background-color: #2878e5; }
#dash { padding: 7px 10px; background-color: rgba(238,245,255,0.76); border: 1px solid rgba(255,255,255,0.62); border-radius: 18px; }
.dash-item-container .app-well-app, .app-well-app { border-radius: 12px; }
.overview-controls { spacing: 24px; }
.search-entry { color: #17243a; background-color: rgba(255,255,255,0.94); border: 1px solid rgba(40,120,229,0.28); border-radius: 13px; }
SHELL

cat > /etc/skel/.config/gtk-4.0/gtk.css <<'GTK4'
/* SbeamOS Aurora — libadwaita accent and surface refinements */
@define-color accent_color #2878e5;
@define-color accent_bg_color #2878e5;
@define-color accent_fg_color #ffffff;
@define-color window_bg_color #f4f7fc;
@define-color window_fg_color #17243a;
@define-color view_bg_color #ffffff;
@define-color view_fg_color #17243a;
@define-color headerbar_bg_color #f8faff;
@define-color headerbar_fg_color #17243a;
@define-color card_bg_color #ffffff;
@define-color popover_bg_color #ffffff;
@define-color popover_fg_color #17243a;
@define-color sidebar_bg_color #edf2fa;
@define-color sidebar_fg_color #30435f;
@define-color borders rgba(37,65,105,0.14);

window, .background { background: #f4f7fc; }
headerbar { background: linear-gradient(to bottom, #ffffff, #f5f8fd); box-shadow: 0 1px 0 rgba(37,65,105,0.10); }
button.pill:checked, button.suggested-action { background: #2878e5; color: #ffffff; }
.navigation-sidebar row:selected { background: #dceaff; color: #124f9f; }
card, .card { border: 1px solid rgba(37,65,105,0.10); border-radius: 14px; box-shadow: 0 2px 10px rgba(23,36,58,0.04); }
GTK4

log "Creating SbeamOS icon theme with original branded folder and app marks..."
cat > "$ICON_DIR/index.theme" <<'ICONS'
[Icon Theme]
Name=SbeamOS
Comment=SbeamOS Aurora icon theme
Inherits=Adwaita,hicolor
Directories=scalable/places,scalable/apps,scalable/status

[scalable/places]
Size=64
Type=Scalable
MinSize=16
MaxSize=512
Context=Places

[scalable/apps]
Size=64
Type=Scalable
MinSize=16
MaxSize=512
Context=Applications

[scalable/status]
Size=64
Type=Scalable
MinSize=16
MaxSize=512
Context=Status
ICONS
cat > "$ICON_DIR/scalable/places/folder.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#64b5ff"/><stop offset="1" stop-color="#2878e5"/></linearGradient></defs><path d="M6 17a6 6 0 0 1 6-6h15l6 7h19a6 6 0 0 1 6 6v25a6 6 0 0 1-6 6H12a6 6 0 0 1-6-6z" fill="url(#g)"/><path d="M6 25h52v24a6 6 0 0 1-6 6H12a6 6 0 0 1-6-6z" fill="#4a9bf0"/><path d="M9 28h46" stroke="#b9ddff" stroke-width="2" opacity=".8"/></svg>
SVG
cat > "$ICON_DIR/scalable/apps/sbeamos.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#65c8ff"/><stop offset="1" stop-color="#2468d8"/></linearGradient></defs><rect x="3" y="3" width="58" height="58" rx="17" fill="url(#g)"/><path d="M17 21h30M17 32h21M17 43h30" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round"/><circle cx="45" cy="32" r="4" fill="#d9f2ff"/></svg>
SVG

log "Installing pinned GNOME extensions used by the SbeamOS desktop..."
clone_pinned https://github.com/aunetx/blur-my-shell.git \
  3556b496cfdcd3303f9d56f8c828d94c39965660 "$BLUR_REPO"
make -C "$BLUR_REPO" build
BLUR_EXTENSION_DIR=/usr/share/gnome-shell/extensions/blur-my-shell@aunetx
install -d -m 0755 "$BLUR_EXTENSION_DIR"
unzip -oq "$BLUR_REPO/build/blur-my-shell@aunetx.shell-extension.zip" -d "$BLUR_EXTENSION_DIR"
clone_pinned https://github.com/kem-a/kiwi-menu.git \
  9cb445430b30f182fb2c7ec32cc4c027bc792c0e "$KIWI_REPO"
KIWI_EXTENSION_DIR=/usr/share/gnome-shell/extensions/kiwimenu@kemma
install -d -m 0755 "$KIWI_EXTENSION_DIR"
cp -a "$KIWI_REPO"/. "$KIWI_EXTENSION_DIR"/
rm -rf "$KIWI_EXTENSION_DIR/.git"

log "Installing extension license notices and SbeamOS theme documentation..."
LICENSE_DIR=/usr/share/doc/sbeamos-theme-licenses
install -d -m 0755 "$LICENSE_DIR"
install -m 0644 "$BLUR_REPO/LICENSE" "$LICENSE_DIR/Blur-my-Shell-GPL-3.0.txt"
install -m 0644 "$KIWI_REPO/LICENSE" "$LICENSE_DIR/Kiwi-Menu-GPL-3.0.txt"
cat > "$LICENSE_DIR/SOURCES.txt" <<'SOURCES'
SbeamOS Aurora is an original SbeamOS theme.
GTK 3, GTK 4/libadwaita overrides, GNOME Shell CSS, icon theme metadata,
and the SbeamOS folder/application SVG icons are maintained in the SbeamOS repository.

Blur my Shell
  https://github.com/aunetx/blur-my-shell
  Commit: 3556b496cfdcd3303f9d56f8c828d94c39965660

Kiwi Menu
  https://github.com/kem-a/kiwi-menu
  Commit: 9cb445430b30f182fb2c7ec32cc4c027bc792c0e
SOURCES

glib-compile-schemas "$BLUR_EXTENSION_DIR/schemas"
glib-compile-schemas "$KIWI_EXTENSION_DIR/schemas"
rm -rf "$WORK_DIR"

log "SbeamOS Aurora theme and icons installed."
