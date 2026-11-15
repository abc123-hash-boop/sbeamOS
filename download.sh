#!/usr/bin/env bash
set -euo pipefail

# Run from this script's directory so all build paths remain portable.
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

# Ubuntu 26.04 (Resolute Raccoon) Minimal RootFS bootstrap settings.
ARCH="amd64"
SUITE="resolute"
MIRROR="http://archive.ubuntu.com/ubuntu/"
ROOTFS="./rootfs"

echo 'Step 1: Download rootfs'

# Build the minimal Ubuntu root filesystem.
sudo debootstrap \
  --arch="${ARCH}" \
  --variant=minbase \
  "${SUITE}" \
  "${ROOTFS}" \
  "${MIRROR}"

echo 'Succeed'
