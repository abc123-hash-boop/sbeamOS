#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf '[INFO] %s\n' "$*"
}

log "Installing the runtime SbeamOS Live user setup..."

install -d -m 0755 /usr/local/sbin
cat > /usr/local/sbin/sbeamos-live-user <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail

LIVE_USER=live
LIVE_HOME="/home/$LIVE_USER"

# Use the kernel command line as the authoritative Live-mode signal. Do not
# rely on a marker below /run, which may be recreated after switch_root.
if ! grep -Eq '(^| )rd\.sbeamos\.live=1( |$)' /proc/cmdline; then
  exit 0
fi

if ! id "$LIVE_USER" >/dev/null 2>&1; then
  useradd --create-home --user-group --shell /bin/bash \
    --comment "SbeamOS Live User" "$LIVE_USER"
fi

for group in adm cdrom dip plugdev sudo users video audio render netdev; do
  if getent group "$group" >/dev/null; then
    usermod --append --groups "$group" "$LIVE_USER"
  fi
done

install -d -m 0755 "$LIVE_HOME"
cp -an /etc/skel/. "$LIVE_HOME/" 2>/dev/null || true
chown -R "$LIVE_USER:$LIVE_USER" "$LIVE_HOME"

install -d -m 0750 /etc/sudoers.d
printf '%s ALL=(ALL:ALL) NOPASSWD:ALL\n' "$LIVE_USER" > /etc/sudoers.d/sbeamos-live
chmod 0440 /etc/sudoers.d/sbeamos-live
visudo -cf /etc/sudoers.d/sbeamos-live >/dev/null

cat > /etc/gdm3/custom.conf <<'GDM'
[daemon]
AutomaticLoginEnable=True
AutomaticLogin=live

[security]

[debug]
GDM

echo "[INFO] SbeamOS Live user is ready; GDM automatic login is enabled."
SCRIPT
chmod 0755 /usr/local/sbin/sbeamos-live-user

cat > /etc/systemd/system/sbeamos-live-user.service <<'UNIT'
[Unit]
Description=Prepare the SbeamOS Live user
Documentation=man:useradd(8)
ConditionKernelCommandLine=rd.sbeamos.live=1
After=local-fs.target systemd-user-sessions.service
Before=display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/sbeamos-live-user
RemainAfterExit=yes

[Install]
WantedBy=graphical.target
UNIT

systemctl enable sbeamos-live-user.service

log "SbeamOS Live user service installed (kernel-command-line detection and GDM autologin)."
