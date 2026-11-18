#!/usr/bin/env bash
set -Eeuo pipefail

# Always operate relative to this script, regardless of the caller's cwd.
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

ROOTFS="./rootfs"
CHROOT_SCRIPTS="./scripts/chroot"
CHROOT_WORKDIR="/root/sbeam-chroot"

log() {
  printf '[INFO] %s\n' "$*"
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

# Mounts are tracked explicitly so cleanup only touches mounts made by this run.
MOUNT_TARGETS=()

cleanup() {
  local status=$?
  trap - EXIT INT TERM

  if (("${#MOUNT_TARGETS[@]}" > 0)); then
    log "Cleaning up chroot mounts..."
    local i target
    for ((i=${#MOUNT_TARGETS[@]} - 1; i >= 0; i--)); do
      target="${MOUNT_TARGETS[i]}"
      if mountpoint -q "$target"; then
        if ! sudo umount -R "$target"; then
          printf '[WARN] Normal unmount failed for %s; trying lazy unmount.\n' "$target" >&2
          sudo umount -Rl "$target" || status=1
        fi
      fi
    done
  fi

  if [[ -d "$ROOTFS" && -d "$ROOTFS/root" ]]; then
    sudo rm -rf "$ROOTFS/root/sbeam-chroot"
  fi

  if ((status == 0)); then
    log "Chroot stage completed."
  else
    printf '[ERROR] Chroot stage failed (exit code: %s).\n' "$status" >&2
  fi
  exit "$status"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

log "Checking RootFS..."
[[ -d "$ROOTFS" ]] || die "RootFS directory not found: $ROOTFS"
[[ -x "$ROOTFS/usr/bin/apt-get" ]] || die "RootFS is incomplete; run ./download.sh first."
[[ -d "$CHROOT_SCRIPTS" ]] || die "Chroot scripts directory not found: $CHROOT_SCRIPTS"
compgen -G "$CHROOT_SCRIPTS/*.sh" >/dev/null || die "No chroot scripts were found."

for path in dev proc sys run; do
  target="$ROOTFS/$path"
  sudo mkdir -p "$target"
  if mountpoint -q "$target"; then
    die "A mount already exists at $target. Unmount it before continuing."
  fi
done

log "Preparing DNS configuration..."
# debootstrap normally copies the host resolver file. Refresh it for this build
# so package installation inside chroot can resolve repository hostnames.
sudo cp -L /etc/resolv.conf "$ROOTFS/etc/resolv.conf"

log "Mounting virtual filesystems..."
sudo mount --rbind /dev "$ROOTFS/dev"
MOUNT_TARGETS+=("$ROOTFS/dev")
sudo mount --make-rslave "$ROOTFS/dev"

sudo mount -t proc proc "$ROOTFS/proc"
MOUNT_TARGETS+=("$ROOTFS/proc")

sudo mount --rbind /sys "$ROOTFS/sys"
MOUNT_TARGETS+=("$ROOTFS/sys")
sudo mount --make-rslave "$ROOTFS/sys"

sudo mount --bind /run "$ROOTFS/run"
MOUNT_TARGETS+=("$ROOTFS/run")
sudo mount --make-rslave "$ROOTFS/run"

log "Copying chroot configuration scripts..."
sudo mkdir -p "$ROOTFS$CHROOT_WORKDIR"
sudo cp -a "$CHROOT_SCRIPTS/." "$ROOTFS$CHROOT_WORKDIR/"
sudo install -m 0644 ./VERSION "$ROOTFS$CHROOT_WORKDIR/VERSION"
sudo install -d -m 0755 "$ROOTFS$CHROOT_WORKDIR/installer"
sudo cp -a ./installer/. "$ROOTFS$CHROOT_WORKDIR/installer/"

log "Entering Ubuntu RootFS..."
sudo chroot "$ROOTFS" /usr/bin/env DEBIAN_FRONTEND=noninteractive \
  /bin/bash "$CHROOT_WORKDIR/run.sh"

log "Leaving chroot environment..."
