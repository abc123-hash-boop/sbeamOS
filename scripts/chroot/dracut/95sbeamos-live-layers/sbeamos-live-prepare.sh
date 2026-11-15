#!/bin/sh

command -v getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

getargbool 0 rd.sbeamos.live || exit 0

live_dir="$(getarg rd.live.dir)"
[ -n "$live_dir" ] || live_dir=LiveOS
squash_image="$(getarg rd.live.squashimg)"
[ -n "$squash_image" ] || squash_image=rootfs.squashfs

case "$live_dir" in
    /*|*..*|*[!A-Za-z0-9_./-]*)
        die "Invalid SbeamOS Live directory: $live_dir"
        exit 1
        ;;
esac
case "$squash_image" in
    */*|*..*|*[!A-Za-z0-9_.-]*)
        die "Invalid SbeamOS Live image name: $squash_image"
        exit 1
        ;;
esac

media_root=/run/initramfs/live
source_image="$media_root/$live_dir/$squash_image"

if [ ! -d "$media_root" ]; then
    die "SbeamOS Live media is unavailable at $media_root"
    exit 1
fi
if [ ! -f "$source_image" ]; then
    die "SbeamOS Live root image is unavailable at $source_image"
    exit 1
fi

mkdir -p "$NEWROOT/cdrom" "$NEWROOT/run/sbeamos-live"
mount --bind "$media_root" "$NEWROOT/cdrom" || {
    die "SbeamOS could not expose the Live media at /cdrom"
    exit 1
}

: > "$NEWROOT/run/sbeamos-live/rootfs.squashfs"
mount --bind "$source_image" "$NEWROOT/run/sbeamos-live/rootfs.squashfs" || {
    die "SbeamOS could not expose the Live root image to the installer"
    exit 1
}

cat > "$NEWROOT/run/sbeamos-live/environment" <<EOF
SBEAMOS_LIVE=1
SBEAMOS_LIVE_MEDIA=/cdrom
SBEAMOS_LIVE_SOURCE=/run/sbeamos-live/rootfs.squashfs
SBEAMOS_LIVE_DIRECTORY=$live_dir
SBEAMOS_LIVE_IMAGE=$squash_image
EOF

info "SbeamOS Live media and installer source contracts are ready"
