#!/usr/bin/env bash
set -euo pipefail
umask 077

die(){ printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass(){ printf 'PASS: %s\n' "$*"; }

# Reads `ufw status verbose` text on stdin. Succeeds only if every inbound
# ALLOW/LIMIT rule targets the SSH port and at least one does. Plain
# `ufw status` has no IN column and must fail.
ufw_ssh_only(){
  awk -v p="$1/tcp" -v pn="$1" '
    { action=$2; dir=$3; if ($2=="(v6)") {action=$3; dir=$4} }
    (action=="ALLOW" || action=="LIMIT") && dir=="IN" {
      if ($1==p || $1==pn) ssh_rules++
      else {bad=1; print "unexpected_ufw_rule=" $0 > "/dev/stderr"}
    }
    END {if (ssh_rules < 1 || bad) exit 1}
  '
}

# check.sh sources this file with VERIFY_LIB_ONLY=1 to test the parser.
if [[ "${VERIFY_LIB_ONLY:-0}" == "1" ]]; then return 0; fi

[[ "$EUID" -eq 0 ]] || die "run as root"

expected_hostname="${EXPECTED_HOSTNAME:-pil-prod-01}"
actual_hostname="$(hostname)"
[[ "$actual_hostname" == "$expected_hostname" ]] || die "hostname mismatch: expected $expected_hostname, got $actual_hostname"
pass "host identity name=$actual_hostname"
printf 'machine_id_sha256=%s\n' "$(sha256sum /etc/machine-id | awk '{print $1}')"

# Swap must exist only in RAM-backed zram.
swap_names="$(awk 'NR>1 {print $1}' /proc/swaps)"
[[ -n "$swap_names" ]] || die "no active zram swap"
bad_swap="$(printf '%s\n' "$swap_names" | grep -v '^/dev/zram' || true)"
[[ -z "$bad_swap" ]] || die "non-zram swap active: $(printf '%s' "$bad_swap" | tr '\n' ' ')"
fstab_swap="$(awk '!/^[[:space:]]*#/ && NF>=3 && $3=="swap" {print $1}' /etc/fstab 2>/dev/null || true)"
[[ -z "$fstab_swap" ]] || die "disk-backed swap configured in /etc/fstab"
pass "swap is zram-only: $(printf '%s' "$swap_names" | tr '\n' ' ')"

runtime_fs="$(findmnt -n -T /run -o FSTYPE)"
[[ "$runtime_fs" == "tmpfs" || "$runtime_fs" == "ramfs" ]] || die "/run is not memory-backed: $runtime_fs"
pass "/run is memory-backed ($runtime_fs)"

# Crash-memory persistence must be disabled.
[[ "$(cat /proc/sys/fs/suid_dumpable)" == "0" ]] || die "fs.suid_dumpable is not 0"
[[ "$(cat /proc/sys/kernel/core_pattern)" == "|/bin/false" ]] || die "kernel.core_pattern does not discard cores"
if [[ -f /etc/default/apport ]]; then
  ! grep -Eq '^enabled=1([[:space:]]*)$' /etc/default/apport || die "Apport is enabled"
fi
# apport.service rewrites core_pattern/suid_dumpable at boot unless masked.
if systemctl cat apport.service >/dev/null 2>&1; then
  [[ "$(systemctl is-enabled apport.service 2>/dev/null || true)" == "masked" ]] || die "apport.service is not masked; it resets core-dump sysctls at boot"
fi
grep -q '^Storage=none$' /etc/systemd/coredump.conf.d/99-architect-privacy.conf || die "systemd coredump storage is not disabled"
grep -q '^ProcessSizeMax=0$' /etc/systemd/coredump.conf.d/99-architect-privacy.conf || die "systemd coredump processing is not disabled"
pass "core-memory persistence disabled"

sshd_bin="$(command -v sshd || true)"
[[ -n "$sshd_bin" ]] || die "sshd missing"
"$sshd_bin" -t
effective_sshd="$("$sshd_bin" -T)"
get_sshd(){ awk -v k="$1" '$1==k{print $2; exit}' <<<"$effective_sshd"; }
ssh_port="$(get_sshd port)"
[[ "$(get_sshd passwordauthentication)" == "no" ]] || die "SSH password auth enabled"
[[ "$(get_sshd kbdinteractiveauthentication)" == "no" ]] || die "SSH keyboard-interactive auth enabled"
permit_root="$(get_sshd permitrootlogin)"
[[ "$permit_root" == "prohibit-password" || "$permit_root" == "without-password" ]] || die "root SSH is not key-only"
[[ "$(get_sshd allowagentforwarding)" == "no" ]] || die "SSH agent forwarding enabled"
[[ "$(get_sshd allowtcpforwarding)" == "no" ]] || die "SSH TCP forwarding enabled"
systemctl is-active --quiet ssh.socket || die "ssh.socket is not active"
listeners="$(ss -lntH)"
awk -v p="$ssh_port" '$4 ~ ("(^|:)" p "$") {found=1} END {exit !found}' <<<"$listeners" || die "SSH not listening on $ssh_port"
pass "key-only socket-activated SSH listening on port $ssh_port"

ufw_text="$(ufw status verbose)"
grep -q '^Status: active$' <<<"$ufw_text" || die "UFW inactive"
grep -q 'Default: deny (incoming), allow (outgoing)' <<<"$ufw_text" || die "UFW defaults are not deny-in/allow-out"
ufw_ssh_only "$ssh_port" <<<"$ufw_text" || die "SSH-only UFW rule verification failed"
pass "UFW default-deny with SSH-only inbound rule"

check_path(){
  local path="$1" expected="$2" actual
  actual="$(stat -c '%U:%G:%a' "$path")"
  [[ "$actual" == "$expected" ]] || die "$path expected $expected got $actual"
}
for spec in "pml:pmlsvc" "pil:pilsvc" "coord:coordsvc"; do
  name="${spec%%:*}"
  user="${spec##*:}"
  shell="$(getent passwd "$user" | cut -d: -f7)"
  [[ "$shell" == "/usr/sbin/nologin" ]] || die "$user has login shell $shell"
  groups=" $(id -nG "$user") "
  [[ "$groups" != *" sudo "* && "$groups" != *" admin "* ]] || die "$user is in an admin group"
  check_path "/srv/$name" "root:root:755"
  check_path "/srv/$name/app" "root:root:755"
  check_path "/srv/$name/state" "$user:$user:700"
  check_path "/srv/$name/artifacts" "$user:$user:700"
  check_path "/etc/$name" "root:$user:750"
  check_path "/run/$name" "$user:$user:750"
  check_path "/run/$name/secrets" "$user:$user:700"
  [[ -z "$(find "/srv/$name/state" "/srv/$name/artifacts" "/run/$name/secrets" -mindepth 1 -print -quit)" ]] || die "$name private paths are not empty before data migration"
done
pass "PML/PIL/coordinator service identities and paths are isolated and empty"

# Nothing database-like or application-like should be listening yet.
postgres_count="$(ss -lntH | awk '$4 ~ /:5432$/ {n++} END {print n+0}')"
[[ "$postgres_count" == "0" ]] || die "PostgreSQL is listening before runtime milestone"
pass "no PostgreSQL listener"

printf 'listeners_begin\n'
ss -lntupH 2>/dev/null | awk '{print $1,$5}' | sort -u || true
printf 'listeners_end\n'
printf 'ARCHITECT_OS_FOUNDATION_VERIFY_PASS\n'
