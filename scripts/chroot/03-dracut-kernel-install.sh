#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

log() {
  printf '[INFO] %s\n' "$*"
}

log "Installing Dracut, hardware detection tools, and the generic kernel..."
apt-get install --yes --no-install-recommends \
  dracut \
  laptop-detect \
  os-prober \
  keyutils \
  dmsetup \
  linux-image-generic

log "Configuring Dracut for a portable, non-host-only initramfs..."
install -d -m 0755 /etc/dracut.conf.d
cat > /etc/dracut.conf.d/10-sbeamos.conf <<'DRACUT'
# Build a portable initramfs that can boot on hardware other than the
# machine used to build the image. Live-root support is added separately.
hostonly="no"
compress="zstd"
DRACUT

log "Generating initramfs images for installed kernels..."
shopt -s nullglob
kernel_images=(/boot/vmlinuz-*)
if (("${#kernel_images[@]}" == 0)); then
  printf '[ERROR] No kernel image was found in /boot.\n' >&2
  exit 1
fi

for image in "${kernel_images[@]}"; do
  kernel_version="${image##*/vmlinuz-}"
  log "Generating initramfs for kernel ${kernel_version}..."
  dracut --force --kver "${kernel_version}" "/boot/initrd.img-${kernel_version}"
done

for image in /boot/initrd.img-*; do
  [[ -s "$image" ]] || {
    printf '[ERROR] Initramfs image is missing or empty: %s\n' "$image" >&2
    exit 1
  }
done

log "Dracut and generic kernel installation completed."
