#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

log() {
  printf '[INFO] %s\n' "$*"
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

architecture="$(dpkg --print-architecture)"
[[ "$architecture" == "amd64" ]] || die "Google Chrome Stable is configured for SbeamOS amd64 builds; found: $architecture"

log "Installing Google Chrome Stable from Google's official Debian package..."

apt-get install --yes --no-install-recommends \
  ca-certificates \
  curl \
  xdg-utils

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
deb_file="$tmp_dir/google-chrome-stable_current_amd64.deb"

curl --fail --location --show-error --silent \
  --retry 3 --retry-delay 2 --connect-timeout 30 \
  --output "$deb_file" \
  https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

[[ -s "$deb_file" ]] || die "Google Chrome package download is empty."
package_name="$(dpkg-deb --field "$deb_file" Package)"
package_arch="$(dpkg-deb --field "$deb_file" Architecture)"
package_version="$(dpkg-deb --field "$deb_file" Version)"

[[ "$package_name" == "google-chrome-stable" ]] || die "Unexpected package name: $package_name"
[[ "$package_arch" == "amd64" ]] || die "Unexpected Chrome package architecture: $package_arch"

log "Installing Google Chrome $package_version..."
apt-get install --yes --no-install-recommends "$deb_file"

command -v google-chrome >/dev/null 2>&1 || die "Google Chrome executable was not installed."
[[ -f /usr/share/applications/google-chrome.desktop ]] || die "Google Chrome desktop launcher is missing."

# Set Chrome as the system default for web links and HTML documents.
# /etc/skel also applies these defaults to the runtime-created Live user.
mimeapps_content='[Default Applications]
x-scheme-handler/http=google-chrome.desktop
x-scheme-handler/https=google-chrome.desktop
text/html=google-chrome.desktop
application/xhtml+xml=google-chrome.desktop
'

install -d -m 0755 /etc/xdg /etc/skel/.config
printf '%s\n' "$mimeapps_content" > /etc/xdg/mimeapps.list
printf '%s\n' "$mimeapps_content" > /etc/skel/.config/mimeapps.list
chmod 0644 /etc/xdg/mimeapps.list /etc/skel/.config/mimeapps.list

log "Google Chrome Stable installed and registered as the default browser."
log "The official Google APT repository configured by the DEB package will provide future updates."
