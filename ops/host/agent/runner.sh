#!/usr/bin/env bash
set -euo pipefail
umask 077

op="${1:-}"
request_id="${2:-}"
[[ "$request_id" =~ ^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$ ]] || { echo "bad request id" >&2; exit 64; }

case "$op" in
  status)
    current="$(uname -r)"
    latest="$(ls -1 /lib/modules 2>/dev/null | sort -V | tail -1 || true)"
    echo "kernel_current=$current"
    echo "kernel_latest=$latest"
    if [[ -n "$latest" ]] && find "/lib/modules/$latest" -name 'zram.ko*' -print -quit 2>/dev/null | grep -q .; then
      echo "latest_kernel_has_zram=true"
    else
      echo "latest_kernel_has_zram=false"
    fi
    echo "uptime_seconds=$(cut -d. -f1 </proc/uptime)"
    echo "swap_begin"
    /usr/sbin/swapon --show --noheadings --raw || true
    echo "swap_end"
    echo "ufw_begin"
    /usr/sbin/ufw status verbose || true
    echo "ufw_end"
    ;;
  verify_os)
    exec /usr/local/libexec/pcs-host-agent/11-verify-os-security.sh
    ;;
  apply_os_security)
    exec /usr/local/libexec/pcs-host-agent/10-os-security.sh
    ;;
  install_kernel_virtual)
    export DEBIAN_FRONTEND=noninteractive
    /usr/bin/apt-get update
    /usr/bin/apt-get install -y linux-virtual linux-image-virtual linux-headers-virtual linux-headers-generic linux-libc-dev linux-tools-common
    latest="$(ls -1 /lib/modules | sort -V | tail -1)"
    [[ -n "$latest" ]] || { echo "no installed kernel modules found" >&2; exit 70; }
    find "/lib/modules/$latest" -name 'zram.ko*' -print -quit | grep -q . || { echo "latest kernel lacks zram module: $latest" >&2; exit 70; }
    echo "kernel_latest=$latest"
    echo "latest_kernel_has_zram=true"
    ;;
  reboot)
    unit="pcs-host-agent-reboot-${request_id//[^A-Za-z0-9_.:-]/_}"
    /usr/bin/systemd-run --unit="$unit" --on-active=3s /usr/bin/systemctl reboot >/dev/null
    echo "reboot_scheduled=true"
    ;;
  *)
    echo "operation not allowed" >&2
    exit 64
    ;;
esac