"""Destructive installation engine. All disk writes are isolated here."""
from __future__ import annotations

import os
import re
import shutil
import subprocess
import tempfile
import uuid
from pathlib import Path

from .disks import validate_target

LIVE_IMAGE_CANDIDATES = (
    Path("/run/sbeamos-live/rootfs.squashfs"),
    Path("/cdrom/LiveOS/rootfs.squashfs"),
    Path("/run/initramfs/live/LiveOS/rootfs.squashfs"),
)
LOCK_FILE = "/run/lock/sbeamos-installer.lock"


def _run(args: list[str], log, *, input_text: str | None = None) -> None:
    log("$ " + " ".join(args))
    result = subprocess.run(args, text=True, input=input_text,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    for line in result.stdout.splitlines():
        log(line)
    if result.returncode:
        raise RuntimeError(f"Command failed ({result.returncode}): {' '.join(args)}")


def _partition_names(disk: str) -> tuple[str, str, str]:
    if re.search(r"\d$", disk):
        return disk + "p1", disk + "p2", disk + "p3"
    return disk + "1", disk + "2", disk + "3"


def install_system(disk_path: str, expected_identity: tuple[int, str, str],
                   username: str, password: str, hostname: str, log) -> None:
    """Install the Live SquashFS to a freshly partitioned GPT target disk."""
    import fcntl

    if os.geteuid() != 0:
        raise RuntimeError("The installer must run with administrator privileges.")
    if not re.fullmatch(r"[a-z_][a-z0-9_-]{0,30}\$?", username):
        raise ValueError("Username must start with a lowercase letter or underscore.")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]{0,62}", hostname):
        raise ValueError("Hostname contains unsupported characters.")
    if len(password) < 8:
        raise ValueError("Choose a password with at least 8 characters.")
    live_image = next((path for path in LIVE_IMAGE_CANDIDATES if path.is_file()), None)
    if live_image is None:
        searched = ", ".join(str(path) for path in LIVE_IMAGE_CANDIDATES)
        raise RuntimeError(f"Live system image not found. Searched: {searched}")

    os.makedirs(os.path.dirname(LOCK_FILE), exist_ok=True)
    with open(LOCK_FILE, "w", encoding="utf-8") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise RuntimeError("Another SbeamOS installation is already running.") from exc

        disk = validate_target(disk_path)
        current_identity = (disk.size, disk.serial, disk.model)
        if current_identity != expected_identity:
            raise RuntimeError(
                "The selected disk identity changed since it was scanned. "
                "No changes were made; rescan the disks and try again."
            )
        # Verify the source is a SquashFS image before any destructive operation.
        with live_image.open("rb") as image:
            if image.read(4) != b"hsqs":
                raise RuntimeError("The Live installation source is not a valid SquashFS image.")

        root_part, efi_part, bios_part = _partition_names(disk.path)
        work = Path(tempfile.mkdtemp(prefix="sbeamos-install-"))
        source = work / "source"
        target = work / "target"
        efi = target / "boot" / "efi"
        mounted: list[Path] = []
        try:
            # Re-read the block-device identity immediately before the first
            # destructive command to reduce the chance of targeting a swapped disk.
            fresh_disk = validate_target(disk.path)
            if (fresh_disk.size, fresh_disk.serial, fresh_disk.model) != expected_identity:
                raise RuntimeError("The target disk changed before partitioning; no disk writes were started.")
            log(f"Target disk: {disk.path} ({disk.size} bytes)")
            log("WARNING: all existing data on the selected disk will be erased.")
            _run(["wipefs", "--all", "--force", disk.path], log)
            _run(["parted", "--script", disk.path, "mklabel", "gpt"], log)
            _run(["parted", "--script", disk.path, "mkpart", "BIOS", "1MiB", "2MiB"], log)
            _run(["parted", "--script", disk.path, "set", "1", "bios_grub", "on"], log)
            _run(["parted", "--script", disk.path, "mkpart", "EFI", "fat32", "2MiB", "514MiB"], log)
            _run(["parted", "--script", disk.path, "set", "2", "esp", "on"], log)
            _run(["parted", "--script", disk.path, "mkpart", "root", "ext4", "514MiB", "100%"], log)
            _run(["partprobe", disk.path], log)
            _run(["udevadm", "settle"], log)

            sector_size = _run_capture(["blockdev", "--getss", disk.path])
            _run(["mkfs.fat", "-F", "32", "-S", sector_size, efi_part], log)
            _run(["mkfs.ext4", "-F", "-L", "SbeamOS", root_part], log)

            source.mkdir()
            target.mkdir()
            _run(["mount", "-o", "loop,ro", str(live_image), str(source)], log)
            mounted.append(source)
            _run(["mount", root_part, str(target)], log)
            mounted.append(target)
            efi.mkdir(parents=True, exist_ok=True)
            _run(["mount", efi_part, str(efi)], log)
            mounted.append(efi)

            log("Copying the SbeamOS system image. This may take several minutes.")
            _run(["rsync", "-aHAXx", "--numeric-ids", "--info=progress2",
                  "--exclude=/dev/*", "--exclude=/proc/*", "--exclude=/sys/*",
                  "--exclude=/run/*", "--exclude=/tmp/*", str(source) + "/", str(target) + "/"], log)

            root_uuid = _run_capture(["blkid", "-s", "UUID", "-o", "value", root_part])
            efi_uuid = _run_capture(["blkid", "-s", "UUID", "-o", "value", efi_part])
            (target / "etc/fstab").write_text(
                f"UUID={root_uuid} / ext4 defaults,noatime 0 1\n"
                f"UUID={efi_uuid} /boot/efi vfat umask=0077 0 1\n",
                encoding="utf-8")
            (target / "etc/hostname").write_text(hostname + "\n", encoding="utf-8")
            (target / "etc/hosts").write_text(
                f"127.0.0.1 localhost\n127.0.1.1 {hostname}\n"
                "::1 localhost ip6-localhost ip6-loopback\n", encoding="utf-8")

            for directory in ("dev", "proc", "sys", "run"):
                mountpoint = target / directory
                mountpoint.mkdir(parents=True, exist_ok=True)
                _run(["mount", "--rbind", f"/{directory}", str(mountpoint)], log)
                mounted.append(mountpoint)

            # The Live session account and its passwordless sudo rule must not
            # survive into the installed system.
            _run(["systemctl", f"--root={target}", "disable",
                  "sbeamos-live-user.service"], log)
            if any(line.startswith("live:") for line in
                   (target / "etc/passwd").read_text(encoding="utf-8").splitlines()):
                _run(["chroot", str(target), "userdel", "--remove", "live"], log)
            (target / "etc/sudoers.d/sbeamos-live").unlink(missing_ok=True)
            (target / "usr/local/sbin/sbeamos-live-user").unlink(missing_ok=True)
            (target / "etc/systemd/system/sbeamos-live-user.service").unlink(missing_ok=True)
            _run(["chroot", str(target), "useradd", "--create-home",
                  "--shell", "/bin/bash", "--groups", "adm,sudo,audio,video,plugdev",
                  username], log)
            _run(["chroot", str(target), "chpasswd"], log,
                 input_text=f"{username}:{password}\n")
            _run(["systemctl", f"--root={target}", "enable", "gdm3.service"], log)
            _run(["systemctl", f"--root={target}", "set-default", "graphical.target"], log)
            _run(["chroot", str(target), "dracut", "--force", "--no-hostonly",
                  "--no-hostonly-cmdline",
                  f"/boot/initrd.img-{_kernel_version(target)}", _kernel_version(target)], log)
            _run(["chroot", str(target), "grub-install", "--target=i386-pc",
                  "--recheck", disk.path], log)
            _run(["chroot", str(target), "grub-install", "--target=x86_64-efi",
                  "--efi-directory=/boot/efi", "--bootloader-id=SbeamOS",
                  "--no-nvram", "--removable"], log)
            _run(["chroot", str(target), "update-grub"], log)
            machine_id = uuid.uuid4().hex
            (target / "etc/machine-id").write_text(machine_id + "\n", encoding="utf-8")
            (target / "var/lib/dbus/machine-id").unlink(missing_ok=True)
            _run(["chroot", str(target), "ln", "-sf", "/etc/machine-id",
                  "/var/lib/dbus/machine-id"], log)
            log("Installation completed successfully.")
        finally:
            for mountpoint in reversed(mounted):
                if os.path.ismount(mountpoint):
                    result = subprocess.run(
                        ["umount", "-R", str(mountpoint)],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    if result.returncode and os.path.ismount(mountpoint):
                        log(f"[WARN] Could not unmount {mountpoint}; leaving work directory intact.")
            if any(os.path.ismount(mountpoint) for mountpoint in mounted):
                log(f"[WARN] Installation mounts remain. Inspect and unmount them before cleanup: {work}")
            else:
                shutil.rmtree(work, ignore_errors=True)


def _run_capture(args: list[str]) -> str:
    result = subprocess.run(args, check=True, text=True, capture_output=True)
    return result.stdout.strip()


def _kernel_version(target: Path) -> str:
    modules = target / "lib/modules"
    versions = sorted((p.name for p in modules.iterdir() if p.is_dir()),
                      key=lambda value: tuple(int(x) if x.isdigit() else x
                                              for x in re.split(r"([0-9]+)", value)))
    if not versions:
        raise RuntimeError("No installed kernel was found in the target system.")
    return versions[-1]
