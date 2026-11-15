#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

log() {
  printf '[INFO] %s\n' "$*"
}

log "Updating APT package indexes..."
apt-get -o APT::Update::Error-Mode=any update

log "Installing SbeamOS base system packages..."
apt-get install --yes --no-install-recommends \
  apparmor \
  bash-completion \
  bind9-dnsutils \
  bolt \
  ca-certificates \
  command-not-found \
  coreutils \
  cpio \
  crash \
  cron \
  curl \
  debconf-i18n \
  dmidecode \
  dosfstools \
  ed \
  ethtool \
  fdisk \
  file \
  firmware-sof-signed \
  grub2-common \
  hdparm \
  hwdata \
  iproute2 \
  iptables \
  iputils-ping \
  kmod \
  libfuse3-4 \
  libopengl0 \
  libpam-cap \
  libpam-fprintd \
  libpam-modules \
  libpam-modules-bin \
  libpam-pwquality \
  libpam-systemd \
  linux-base \
  linux-firmware \
  locales \
  logrotate \
  lshw \
  lsof \
  man-db \
  manpages \
  media-types \
  mtr-tiny \
  network-manager \
  netplan.io \
  nftables \
  numactl \
  openssh-client \
  parted \
  pciutils \
  powermgmt-base \
  psmisc \
  python3-rich \
  python3-systemd \
  rsync \
  strace \
  sudo \
  systemd-resolved \
  systemd-sysv \
  tcpdump \
  time \
  tzdata \
  ufw \
  unzip \
  usb-modeswitch \
  usbutils \
  uuid-runtime \
  wget \
  wpasupplicant \
  xauth \
  xz-utils \
  zstd \
  zip \
  dbus \
  dbus-user-session \
  dnsmasq-base \
  dns-root-data \
  dhcpcd-base \
  eject \
  gettext \
  cracklib-runtime \
  efibootmgr \
  modemmanager \
  libmbim-utils

log "Configuring locale..."
if ! grep -qE '^en_US.UTF-8 UTF-8$' /etc/locale.gen; then
  printf 'en_US.UTF-8 UTF-8\n' >> /etc/locale.gen
fi
locale-gen en_US.UTF-8
printf 'LANG=en_US.UTF-8\n' > /etc/default/locale

log "Configuring timezone..."
ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
printf 'Etc/UTC\n' > /etc/timezone
dpkg-reconfigure --frontend=noninteractive tzdata

log "Enabling network services..."
systemctl enable NetworkManager.service
systemctl enable systemd-resolved.service
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

log "Base system configuration completed."
