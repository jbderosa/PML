#!/usr/bin/env bash
set -euo pipefail
umask 077

echo "PML_HOST_BASELINE_V1"
printf 'timestamp_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'hostname=%s\n' "$(hostname)"
printf 'machine_id_sha256=%s\n' "$(sha256sum /etc/machine-id | awk '{print $1}')"
printf 'os='
. /etc/os-release
printf '%s %s\n' "$NAME" "$VERSION_ID"
printf 'kernel=%s\n' "$(uname -r)"
printf 'arch=%s\n' "$(uname -m)"
printf 'boot_id=%s\n' "$(cat /proc/sys/kernel/random/boot_id)"
printf 'mem_total_kib=%s\n' "$(awk '/^MemTotal:/{print $2}' /proc/meminfo)"
printf 'root_fs='
findmnt -n -o SOURCE,FSTYPE,OPTIONS /
printf 'disk_root='
df -B1 --output=size,used,avail,pcent / | tail -n1 | xargs
printf 'swap_begin\n'
swapon --show --bytes --noheadings --output=NAME,TYPE,SIZE,USED,PRIO || true
printf 'swap_end\n'
printf 'listeners_begin\n'
ss -lntupH 2>/dev/null | awk '{print $1,$5}' | sort -u || true
printf 'listeners_end\n'
printf 'failed_units_begin\n'
systemctl --failed --no-legend --plain 2>/dev/null || true
printf 'failed_units_end\n'
printf 'ssh_enabled=%s\n' "$(systemctl is-enabled ssh 2>/dev/null || true)"
printf 'ssh_active=%s\n' "$(systemctl is-active ssh 2>/dev/null || true)"
printf 'ufw_status=%s\n' "$(ufw status 2>/dev/null | head -n1 || true)"
printf 'docker_present=%s\n' "$(command -v docker >/dev/null 2>&1 && echo yes || echo no)"
printf 'compose_present=%s\n' "$(docker compose version >/dev/null 2>&1 && echo yes || echo no)"
printf 'zram_present=%s\n' "$(command -v zramswap >/dev/null 2>&1 && echo yes || echo no)"
printf 'postgres_listener_count=%s\n' "$(ss -lntH 2>/dev/null | awk '$4 ~ /:5432$/ {n++} END {print n+0}')"
printf 'core_pattern=%s\n' "$(cat /proc/sys/kernel/core_pattern 2>/dev/null || true)"
printf 'PML_HOST_BASELINE_END\n'
