"""Read-only discovery and validation of installation target disks."""
from __future__ import annotations

import json
import os
import subprocess
from dataclasses import dataclass


@dataclass(frozen=True)
class Disk:
    path: str
    name: str
    size: int
    model: str
    serial: str
    transport: str
    removable: bool
    read_only: bool
    mountpoints: tuple[str, ...]

    @property
    def display(self) -> str:
        gib = self.size / (1024 ** 3)
        detail = " ".join(x for x in (self.model.strip(), self.transport) if x)
        return f"{self.path} — {gib:.1f} GiB" + (f" — {detail}" if detail else "")


def _run(args: list[str]) -> str:
    result = subprocess.run(args, check=True, text=True, capture_output=True)
    return result.stdout


def _mountpoints(node: dict) -> list[str]:
    values = []
    mp = node.get("mountpoints") or [node.get("mountpoint")]
    values.extend(x for x in mp if x)
    for child in node.get("children") or []:
        values.extend(_mountpoints(child))
    return values


def list_disks() -> list[Disk]:
    data = json.loads(_run([
        "lsblk", "--json", "--bytes", "--paths",
        "--output", "NAME,TYPE,SIZE,MODEL,SERIAL,TRAN,RM,RO,MOUNTPOINTS"
    ]))
    disks = []
    for item in data.get("blockdevices", []):
        if item.get("type") != "disk":
            continue
        path = os.path.realpath(item.get("name") or "")
        if not path.startswith("/dev/") or not os.path.exists(path):
            continue
        disks.append(Disk(
            path=path,
            name=item.get("name") or path,
            size=int(item.get("size") or 0),
            model=item.get("model") or "Unknown disk",
            serial=item.get("serial") or "",
            transport=item.get("tran") or "",
            removable=bool(int(item.get("rm") or 0)),
            read_only=bool(int(item.get("ro") or 0)),
            mountpoints=tuple(_mountpoints(item)),
        ))
    return disks


def validate_target(path: str) -> Disk:
    """Re-scan and reject any disk that could contain the running Live system."""
    matches = [d for d in list_disks() if d.path == os.path.realpath(path)]
    if len(matches) != 1:
        raise ValueError("The selected disk is no longer available. Rescan and select it again.")
    disk = matches[0]
    if disk.size < 16 * 1024 ** 3:
        raise ValueError("The selected disk is smaller than the 16 GiB minimum.")
    if disk.removable:
        raise ValueError("Removable disks are not supported as installation targets.")
    if disk.read_only:
        raise ValueError("The selected disk is read-only.")
    if disk.mountpoints:
        raise ValueError("The selected disk has mounted filesystems: " + ", ".join(disk.mountpoints))
    if not os.path.exists("/run/sbeamos-live/rootfs.squashfs"):
        raise ValueError("The SbeamOS Live installation image is not available.")
    return disk
