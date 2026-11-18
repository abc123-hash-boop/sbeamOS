# SbeamOS Installer

A native Python 3 / GTK 3 installer designed for the Dracut-based SbeamOS Live
environment.

## Implemented

- Read-only disk discovery using lsblk.
- Rejects removable, read-only, mounted and undersized target disks.
- Requires the Live SquashFS image at /run/sbeamos-live/rootfs.squashfs and
  validates its SquashFS magic before touching the target.
- Creates a GPT layout with a BIOS boot partition, EFI System Partition and
  ext4 root partition.
- Copies the Live system with rsync while preserving ACLs, hard links and xattrs.
- Writes UUID-based fstab, creates a user, configures GDM, Dracut and GRUB.
- Uses a process lock to prevent simultaneous installer runs.

## Important limitations

This is an early installer implementation. It erases the selected disk and
currently performs a fresh installation only; it does not support dual boot,
manual partitioning, encryption, RAID, LVM, Btrfs, or preserving existing data.
Disk validation is intentionally conservative and refuses disks with mounted
filesystems. It has not been validated end-to-end on physical hardware or under
both BIOS and UEFI QEMU firmware. Do not use it on disks containing data you
need to keep.

Exercise the installation engine only against disposable virtual disks until
the BIOS/UEFI test matrix has passed.
