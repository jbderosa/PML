#!/usr/bin/env bash
set -euo pipefail
umask 077

die(){ printf 'BLOCKED: %s\n' "$*" >&2; exit 1; }
[[ "$EUID" -eq 0 ]] || die "run as root"

# Privacy gate: this design uses zram-only swap. Refuse to modify a host that
# already has disk-backed swap configured or active; review that state first.
non_zram_active="$(swapon --noheadings --raw --output=NAME 2>/dev/null | grep -v '^/dev/zram' || true)"
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

# No disk-backed swap: compressed swap exists only in RAM.
cat >/etc/default/zramswap <<'EOF'
ALGO=lz4
PERCENT=50
PRIORITY=100
EOF
systemctl enable --now zramswap.service
active_swap="$(swapon --noheadings --raw --output=NAME 2>/dev/null || true)"
bad_swap="$(printf '%s\n' "$active_swap" | sed '/^$/d' | grep -v '^/dev/zram' || true)"
[[ -z "$bad_swap" ]] || die "privacy gate failed; non-zram swap became active: $(printf '%s' "$bad_swap" | tr '\n' ' ')"

# Disable ordinary core-dump persistence.
install -d -m 0755 /etc/systemd/coredump.conf.d
cat >/etc/systemd/coredump.conf.d/99-pml-privacy.conf <<'EOF'
[Coredump]
Storage=none
ProcessSizeMax=0
EOF
cat >/etc/security/limits.d/99-pml-no-core.conf <<'EOF'
* hard core 0
* soft core 0
EOF
cat >/etc/sysctl.d/99-pml-privacy.conf <<'EOF'
fs.suid_dumpable=0
kernel.dmesg_restrict=1
kernel.kptr_restrict=2
EOF
sysctl --system >/dev/null

# Separate service identities. None receives login or sudo rights.
ensure_service_user(){
  local user="$1"
  if ! id -u "$user" >/dev/null 2>&1; then
    useradd --system --user-group --no-create-home --shell /usr/sbin/nologin "$user"
  fi
}
ensure_service_user pmlsvc
ensure_service_user pilsvc
ensure_service_user coordsvc

for spec in "pml:pmlsvc" "pil:pilsvc" "coord:coordsvc"; do
  name="$(printf '%s' "$spec" | cut -d: -f1)"
  user="$(printf '%s' "$spec" | cut -d: -f2)"
  install -d -m 0755 -o root -g root "/srv/$name"
  install -d -m 0700 -o "$user" -g "$user" "/srv/$name/data" "/srv/$name/work"
  install -d -m 0750 -o root -g "$user" "/etc/$name"
done

# /run is memory-backed on supported Ubuntu hosts. Runtime secrets live here.
cat >/etc/tmpfiles.d/pml-shared-services.conf <<'EOF'
d /run/pml 0750 pmlsvc pmlsvc -
d /run/pml/secrets 0700 pmlsvc pmlsvc -
d /run/pil 0750 pilsvc pilsvc -
d /run/pil/secrets 0700 pilsvc pilsvc -
d /run/coord 0750 coordsvc coordsvc -
d /run/coord/secrets 0700 coordsvc coordsvc -
EOF
systemd-tmpfiles --create /etc/tmpfiles.d/pml-shared-services.conf
findmnt -n -T /run -o FSTYPE | grep -Eq '^(tmpfs|ramfs)$' || die "/run is not memory-backed"

# Keep password SSH disabled. Recovery Console remains out-of-band.
sshd_bin="$(command -v sshd || true)"
[[ -n "$sshd_bin" ]] || die "sshd is not installed"
ssh_port="$("$sshd_bin" -T | awk '$1=="port"{print $2; exit}')"
[[ "$ssh_port" =~ ^[0-9]+$ ]] || die "could not determine SSH port"

install -d -m 0755 /etc/ssh/sshd_config.d
cat >/etc/ssh/sshd_config.d/90-pml-foundation.conf <<'EOF'
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
PermitRootLogin prohibit-password
X11Forwarding no
AllowAgentForwarding no
PermitTunnel no
MaxAuthTries 3
LoginGraceTime 30
EOF
"$sshd_bin" -t

ufw default deny incoming
ufw default allow outgoing
ufw allow "$ssh_port/tcp" comment 'PML key-only SSH'
ufw --force enable
systemctl enable ssh
systemctl restart ssh

# Explicitly retain Ubuntu's daily security-update path; do not auto-reboot.
cat >/etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
cat >/etc/apt/apt.conf.d/52pml-no-auto-reboot <<'EOF'
Unattended-Upgrade::Automatic-Reboot "false";
EOF

printf 'PML_OS_FOUNDATION_V1_OK\n'
printf 'ssh_port=%s\n' "$ssh_port"
printf 'swap=\n'
swapon --show --noheadings --output=NAME,TYPE,SIZE,USED,PRIO || true
printf 'ufw=\n'
ufw status verbose
printf 'runtime_fs=%s\n' "$(findmnt -n -T /run -o FSTYPE)"
