"""GTK 3 graphical installer entry point."""
from __future__ import annotations

import threading
import gi

gi.require_version("Gtk", "3.0")
from gi.repository import GLib, Gtk

from .disks import list_disks
from .engine import install_system


class InstallerWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Install SbeamOS")
        self.set_default_size(760, 620)
        self.set_border_width(22)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.disks = []
        self.busy = False
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        self.add(root)
        title = Gtk.Label()
        title.set_markup("<span size='xx-large' weight='bold'>Install SbeamOS</span>")
        title.set_xalign(0)
        root.pack_start(title, False, False, 0)
        intro = Gtk.Label(label="Install SbeamOS on your computer")
        intro.set_xalign(0)
        root.pack_start(intro, False, False, 0)
        disk_row = Gtk.Box(spacing=8)
        disk_label = Gtk.Label(label="Installation disk")
        disk_label.set_xalign(0)
        disk_row.pack_start(disk_label, False, False, 0)
        self.disk_combo = Gtk.ComboBoxText()
        self.disk_combo.set_hexpand(True)
        disk_row.pack_start(self.disk_combo, True, True, 0)
        refresh = Gtk.Button(label="Rescan")
        refresh.connect("clicked", self.refresh_disks)
        disk_row.pack_start(refresh, False, False, 0)
        root.pack_start(disk_row, False, False, 0)
        self.warning = Gtk.Label()
        self.warning.set_xalign(0)
        self.warning.set_line_wrap(True)
        root.pack_start(self.warning, False, False, 0)
        grid = Gtk.Grid(column_spacing=12, row_spacing=10)
        root.pack_start(grid, False, False, 0)
        self.username = self._entry(grid, "Username", 0, "e.g. alex")
        self.hostname = self._entry(grid, "Computer name", 1, "sbeamos")
        self.password = self._entry(grid, "Password", 2, "At least 8 characters", secret=True)
        self.password2 = self._entry(grid, "Confirm password", 3, "Enter the password again", secret=True)
        self.erase = Gtk.CheckButton(label="I understand that the selected disk will be completely erased.")
        root.pack_start(self.erase, False, False, 0)
        self.install_button = Gtk.Button(label="Erase disk and install SbeamOS")
        self.install_button.get_style_context().add_class("suggested-action")
        self.install_button.connect("clicked", self.begin_install)
        root.pack_start(self.install_button, False, False, 0)
        log_title = Gtk.Label(label="Installation log")
        log_title.set_xalign(0)
        root.pack_start(log_title, False, False, 0)
        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_min_content_height(170)
        self.log_view = Gtk.TextView()
        self.log_view.set_editable(False)
        self.log_view.set_cursor_visible(False)
        self.log_view.set_monospace(True)
        scroll.add(self.log_view)
        root.pack_start(scroll, True, True, 0)
        self.status = Gtk.Label(label="Ready")
        self.status.set_xalign(0)
        root.pack_start(self.status, False, False, 0)
        self.refresh_disks()

    def _entry(self, grid, label, row, placeholder, secret=False):
        caption = Gtk.Label(label=label)
        caption.set_xalign(0)
        entry = Gtk.Entry()
        entry.set_placeholder_text(placeholder)
        entry.set_visibility(not secret)
        entry.set_hexpand(True)
        grid.attach(caption, 0, row, 1, 1)
        grid.attach(entry, 1, row, 1, 1)
        return entry

    def append_log(self, message):
        def update():
            buffer = self.log_view.get_buffer()
            buffer.insert(buffer.get_end_iter(), message + "\n")
            mark = buffer.create_mark(None, buffer.get_end_iter(), False)
            self.log_view.scroll_to_mark(mark, 0.0, True, 0.0, 1.0)
            return False
        GLib.idle_add(update)

    def refresh_disks(self, *_args):
        self.disk_combo.remove_all()
        self.disks = []
        try:
            self.disks = [
                disk for disk in list_disks()
                if not disk.mountpoints and not disk.removable
                and not disk.read_only and disk.size >= 16 * 1024 ** 3
            ]
            for disk in self.disks:
                self.disk_combo.append(disk.path, disk.display)
            if self.disks:
                self.disk_combo.set_active(0)
            self.warning.set_text(
                "Select a disk with at least 16 GiB. Disks with mounted filesystems, "
                "removable media, and read-only devices will be rejected.")
        except Exception as exc:
            self.warning.set_text(f"Could not scan disks: {exc}")
        return False

    def begin_install(self, *_args):
        if self.busy:
            return
        disk_path = self.disk_combo.get_active_id()
        username = self.username.get_text().strip()
        hostname = self.hostname.get_text().strip()
        password = self.password.get_text()
        if not disk_path:
            self._error("Select an installation disk.")
            return
        if not self.erase.get_active():
            self._error("Confirm that you understand the selected disk will be erased.")
            return
        if password != self.password2.get_text():
            self._error("The passwords do not match.")
            return
        if len(password) < 8:
            self._error("Use a password with at least 8 characters.")
            return
        selected = next((disk for disk in self.disks if disk.path == disk_path), None)
        if selected is None:
            self._error("The selected disk is no longer available. Rescan and try again.")
            return
        identity = (selected.size, selected.serial, selected.model)
        self.busy = True
        self.install_button.set_sensitive(False)
        self.disk_combo.set_sensitive(False)
        self.status.set_text("Installing… Do not power off the computer.")
        self.append_log("Starting SbeamOS installation.")
        threading.Thread(target=self._worker,
                         args=(disk_path, identity, username, password, hostname),
                         daemon=True).start()

    def _worker(self, disk_path, identity, username, password, hostname):
        try:
            install_system(disk_path, identity, username, password, hostname, self.append_log)
            GLib.idle_add(self._finished, True, "Installation completed. Remove the Live USB and reboot.")
        except Exception as exc:
            self.append_log(f"[ERROR] {exc}")
            GLib.idle_add(self._finished, False, str(exc))

    def _finished(self, success, message):
        self.busy = False
        self.password.set_text("")
        self.password2.set_text("")
        self.status.set_text(message)
        self.install_button.set_sensitive(not success)
        if success:
            self.install_button.set_label("Installation complete")
            dialog = Gtk.MessageDialog(
                transient_for=self, flags=0, message_type=Gtk.MessageType.INFO,
                buttons=Gtk.ButtonsType.OK, text="SbeamOS installation complete")
            dialog.format_secondary_text(message)
            dialog.run()
            dialog.destroy()
        else:
            self.disk_combo.set_sensitive(True)
            self._error(message)
        return False

    def _error(self, message):
        dialog = Gtk.MessageDialog(
            transient_for=self, flags=0, message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.CLOSE, text="Unable to continue")
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()


def main():
    if __import__("os").geteuid() != 0:
        print("Launch this installer from the desktop menu so PolicyKit can request administrator access.")
        return 1
    window = InstallerWindow()
    window.connect("destroy", Gtk.main_quit)
    window.show_all()
    Gtk.main()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
