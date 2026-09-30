#!/usr/bin/env bash
set -euo pipefail
umask 077

die(){ printf 'BLOCKED: %s\n' "$*" >&2; exit 1; }
[[ "$EUID" -eq 0 ]] || die "run as root"

sshd_bin="$(command -v sshd || true)"
[[ -n "$sshd_bin" ]] || die "sshd is not installed"
ssh_port="$("$sshd_bin" -T | awk '$1=="port"{print $2; exit}')"
[[ "$ssh_port" =~ ^[0-9]+$ ]] || die "could not determine SSH port"

# Never harden networking unless a public-key login path already exists and
# password authentication is already off. This keeps the script fail-closed.
root_key_count="$(grep -Ec '(^|[[:space:]])(ssh-[A-Za-z0-9-]+|sk-[A-Za-z0-9@._+-]+)[[:space:]]' /root/.ssh/authorized_keys 2>/dev/null || true)"
[[ "${root_key_count:-0}" -ge 1 ]] || die "no root authorized key is installed"

effective_sshd="$("$sshd_bin" -T)"
password_auth="$(printf '%s\n' "$effective_sshd" | awk '$1=="passwordauthentication"{print $2; exit}')"
kbd_auth="$(printf '%s\n' "$effective_sshd" | awk '$1=="kbdinteractiveauthentication"{print $2; exit}')"
permit_root="$(printf '%s\n' "$effective_sshd" | awk '$1=="permitrootlogin"{print $2; exit}')"
[[ "$password_auth" == "no" ]] || die "PasswordAuthentication is not already disabled"
[[ "$kbd_auth" == "no" ]] || die "KbdInteractiveAuthentication is not already disabled"
[[ "$permit_root" == "prohibit-password" || "$permit_root" == "without-password" ]] || die "root login is not key-only"

# Privacy gate: this design uses zram-only swap. Refuse to modify a host that
# already has disk-backed swap configured or active.
non_zram_active="$(awk 'NR>1 && $1 !~ /^\/dev\/zram/ {print $1}' /proc/swaps 2>/dev/null || true)"
[[ -z "$non_zram_active" ]] || die "non-zram swap is active: $(printf '%s' "$non_zram_active" | tr '\n' ' ')"

fstab_swap="$(awk '!/^[[:space:]]*#/ && NF>=3 && $3=="swap" {print $1}' /etc/fstab 2>/dev/null || true)"
[[ -z "$fstab_swap" ]] || die "disk-backed swap is configured in /etc/fstab: $(printf '%s' "$fstab_swap" | tr '\n' ' ')"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  ufw \
  zram-tools \
  unattended-upgrades

# Minimal cloud images can omit the zram kernel module even when zram-tools is
# available. Install the matching extra-module package only when needed.
if ! modprobe zram >/dev/null 2>&1; then
  kernel_extra_pkg="linux-modules-extra-$(uname -r)"
  apt-cache show "$kernel_extra_pkg" >/dev/null 2>&1 || die "zram module missing and $kernel_extra_pkg is unavailable"
  apt-get install -y --no-install-recommends "$kernel_extra_pkg"
  modprobe zram >/dev/null 2>&1 || die "zram module still unavailable after installing $kernel_extra_pkg"
fi

# No disk-backed swap: compressed swap exists only in RAM.
cat >/etc/default/zramswap <<'EOF_ZRAM'
ALGO=lz4
PERCENT=50
PRIORITY=100
EOF_ZRAM
systemctl enable zramswap.service
systemctl restart zramswap.service
active_swap="$(awk 'NR>1 {print $1}' /proc/swaps 2>/dev/null || true)"
bad_swap="$(printf '%s\n' "$active_swap" | sed '/^$/d' | grep -v '^/dev/zram' || true)"
[[ -z "$bad_swap" ]] || die "privacy gate failed; non-zram swap became active: $(printf '%s' "$bad_swap" | tr '\n' ' ')"
printf '%s\n' "$active_swap" | grep -q '^/dev/zram' || die "zram swap did not become active"

# Disable persistent capture of process memory on crashes. Ubuntu stable may
# have Apport installed even when reporting is disabled, and a piped
# kernel.core_pattern can bypass ordinary ulimit core-file controls.
rm -f \
  /etc/systemd/coredump.conf.d/99-pml-privacy.conf \
  /etc/security/limits.d/99-pml-no-core.conf \
  /etc/sysctl.d/99-pml-privacy.conf
install -d -m 0755 /etc/systemd/coredump.conf.d
cat >/etc/systemd/coredump.conf.d/99-architect-privacy.conf <<'EOF_COREDUMP'
[Coredump]
Storage=none
ProcessSizeMax=0
EOF_COREDUMP
cat >/etc/security/limits.d/99-architect-no-core.conf <<'EOF_LIMITS'
* hard core 0
* soft core 0
EOF_LIMITS
if [[ -f /etc/default/apport ]]; then
  if grep -q '^enabled=' /etc/default/apport; then
    sed -i 's/^enabled=.*/enabled=0/' /etc/default/apport
  else
    printf '\nenabled=0\n' >>/etc/default/apport
  fi
fi
cat >/etc/sysctl.d/99-architect-privacy.conf <<'EOF_SYSCTL'
fs.suid_dumpable=0
kernel.dmesg_restrict=1
kernel.kptr_restrict=2
kernel.core_pattern=|/bin/false
EOF_SYSCTL
sysctl --system >/dev/null
[[ "$(cat /proc/sys/fs/suid_dumpable)" == "0" ]] || die "fs.suid_dumpable hardening did not apply"
[[ "$(cat /proc/sys/kernel/core_pattern)" == "|/bin/false" ]] || die "core dump discard handler did not apply"

# Separate application identities. None receives login or sudo rights.
ensure_service_user(){
  local user="$1"
  if ! id -u "$user" >/dev/null 2>&1; then
    useradd --system --user-group --no-create-home --shell /usr/sbin/nologin "$user"
  fi
}
ensure_service_user pmlsvc
ensure_service_user pilsvc
ensure_service_user coordsvc

# Contract-aligned layout. Application code is deployment-controlled/read-only
# to the service identity; mutable state and artifacts are service-private.
for spec in "pml:pmlsvc" "pil:pilsvc" "coord:coordsvc"; do
  name="$(printf '%s' "$spec" | cut -d: -f1)"
  user="$(printf '%s' "$spec" | cut -d: -f2)"
  install -d -m 0755 -o root -g root "/srv/$name" "/srv/$name/app"
  install -d -m 0700 -o "$user" -g "$user" "/srv/$name/state" "/srv/$name/artifacts"
  install -d -m 0750 -o root -g "$user" "/etc/$name"
done

# /run is memory-backed on this Ubuntu host. Runtime secrets live here.
rm -f /etc/tmpfiles.d/pml-shared-services.conf
cat >/etc/tmpfiles.d/architect-shared-services.conf <<'EOF_TMPFILES'
d /run/pml 0750 pmlsvc pmlsvc -
d /run/pml/secrets 0700 pmlsvc pmlsvc -
d /run/pil 0750 pilsvc pilsvc -
d /run/pil/secrets 0700 pilsvc pilsvc -
d /run/coord 0750 coordsvc coordsvc -
d /run/coord/secrets 0700 coordsvc coordsvc -
EOF_TMPFILES
systemd-tmpfiles --create /etc/tmpfiles.d/architect-shared-services.conf
findmnt -n -T /run -o FSTYPE | grep -Eq '^(tmpfs|ramfs)$' || die "/run is not memory-backed"

# Keep password SSH disabled and preserve Ubuntu 24.04 socket activation.
install -d -m 0755 /etc/ssh/sshd_config.d
rm -f /etc/ssh/sshd_config.d/90-pml-foundation.conf /etc/ssh/sshd_config.d/00-pml-hardening.conf
cat >/etc/ssh/sshd_config.d/00-architect-hardening.conf <<'EOF_SSH'
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
PermitRootLogin prohibit-password
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no
MaxAuthTries 3
LoginGraceTime 30
EOF_SSH
"$sshd_bin" -t

effective_sshd="$("$sshd_bin" -T)"
[[ "$(printf '%s\n' "$effective_sshd" | awk '$1=="passwordauthentication"{print $2; exit}')" == "no" ]] || die "effective SSH config permits passwords"
permit_root="$(printf '%s\n' "$effective_sshd" | awk '$1=="permitrootlogin"{print $2; exit}')"
[[ "$permit_root" == "prohibit-password" || "$permit_root" == "without-password" ]] || die "effective root SSH is not key-only"

ufw default deny incoming
ufw default allow outgoing
ufw allow "$ssh_port/tcp" comment 'Architect key-only SSH'
ufw --force enable

# Noble uses socket-activated OpenSSH by default. Keep the socket enabled and
# reload the currently active daemon without converting boot activation modes.
systemctl enable --now ssh.socket
systemctl reload ssh.service
systemctl is-active --quiet ssh.socket || die "ssh.socket is not active"
ss -lntH | awk '{print $4}' | grep -Eq "(^|:)${ssh_port}$" || die "SSH is no longer listening on the expected port"

# Retain Ubuntu's daily security-update path; do not auto-reboot.
cat >/etc/apt/apt.conf.d/20auto-upgrades <<'EOF_UPDATES'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF_UPDATES
cat >/etc/apt/apt.conf.d/52architect-no-auto-reboot <<'EOF_REBOOT'
Unattended-Upgrade::Automatic-Reboot "false";
EOF_REBOOT
rm -f /etc/apt/apt.conf.d/52pml-no-auto-reboot

printf 'ARCHITECT_OS_FOUNDATION_V3_OK\n'
printf 'ssh_port=%s\n' "$ssh_port"
printf 'swap=\n'
cat /proc/swaps
printf 'ufw=\n'
ufw status verbose
printf 'runtime_fs=%s\n' "$(findmnt -n -T /run -o FSTYPE)"
printf 'core_pattern=%s\n' "$(cat /proc/sys/kernel/core_pattern)"
printf 'ssh_socket=%s/%s\n' "$(systemctl is-enabled ssh.socket 2>/dev/null || true)" "$(systemctl is-active ssh.socket 2>/dev/null || true)"
printf 'service_layout=\n'
find /srv/pml /srv/pil /srv/coord -maxdepth 1 -mindepth 1 -printf '%p %u:%g %m\n' | sort
