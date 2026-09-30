#!/usr/bin/env bash
set -euo pipefail
umask 077

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "run as root" >&2
  exit 1
fi

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${PCS_HOST_AGENT_PORT:-8443}"

id coordsvc >/dev/null 2>&1 || { echo "coordsvc user missing; run OS foundation first" >&2; exit 1; }
command -v python3 >/dev/null
command -v openssl >/dev/null
command -v visudo >/dev/null
command -v curl >/dev/null
command -v ss >/dev/null

install -d -o root -g coordsvc -m 0750 /etc/pcs-host-agent /etc/pcs-host-agent/tls
install -d -o coordsvc -g coordsvc -m 0700 /var/lib/pcs-host-agent /var/lib/pcs-host-agent/requests /var/lib/pcs-host-agent/locks
install -d -o root -g root -m 0755 /usr/local/libexec/pcs-host-agent

install -o root -g root -m 0755 "$SRC_DIR/agent.py" /usr/local/libexec/pcs-host-agent/agent.py
install -o root -g root -m 0755 "$SRC_DIR/runner.sh" /usr/local/libexec/pcs-host-agent-runner
install -o root -g root -m 0755 "$SRC_DIR/../10-os-security.sh" /usr/local/libexec/pcs-host-agent/10-os-security.sh
install -o root -g root -m 0755 "$SRC_DIR/../11-verify-os-security.sh" /usr/local/libexec/pcs-host-agent/11-verify-os-security.sh

if [[ ! -s /etc/pcs-host-agent/auth.token ]]; then
  openssl rand -hex 32 >/etc/pcs-host-agent/auth.token
fi
chown root:coordsvc /etc/pcs-host-agent/auth.token
chmod 0640 /etc/pcs-host-agent/auth.token

if [[ ! -s /etc/pcs-host-agent/tls/ca.crt || ! -s /etc/pcs-host-agent/tls/server.crt || ! -s /etc/pcs-host-agent/tls/server.key ]]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  host="$(hostname -f 2>/dev/null || hostname)"
  ips="$(hostname -I 2>/dev/null || true)"
  {
    echo '[req]'
    echo 'distinguished_name=dn'
    echo 'prompt=no'
    echo 'req_extensions=req_ext'
    echo '[dn]'
    echo "CN=$host"
    echo '[req_ext]'
    echo 'subjectAltName=@alt_names'
    echo '[alt_names]'
    echo "DNS.1=$host"
    echo "IP.1=127.0.0.1"
    n=2
    for ip in $ips; do
      [[ "$ip" =~ ^[0-9a-fA-F:.]+$ ]] || continue
      echo "IP.$n=$ip"
      n=$((n+1))
    done
  } >"$tmp/server.cnf"
  openssl genrsa -out "$tmp/ca.key" 3072 >/dev/null 2>&1
  openssl req -x509 -new -key "$tmp/ca.key" -sha256 -days 3650 -subj '/CN=PCS Host Agent Local CA' -out /etc/pcs-host-agent/tls/ca.crt
  openssl genrsa -out /etc/pcs-host-agent/tls/server.key 3072 >/dev/null 2>&1
  openssl req -new -key /etc/pcs-host-agent/tls/server.key -out "$tmp/server.csr" -config "$tmp/server.cnf"
  openssl x509 -req -in "$tmp/server.csr" -CA /etc/pcs-host-agent/tls/ca.crt -CAkey "$tmp/ca.key" -CAcreateserial -out /etc/pcs-host-agent/tls/server.crt -days 825 -sha256 -extensions req_ext -extfile "$tmp/server.cnf"
  chown root:coordsvc /etc/pcs-host-agent/tls/server.key /etc/pcs-host-agent/tls/server.crt /etc/pcs-host-agent/tls/ca.crt
  chmod 0640 /etc/pcs-host-agent/tls/server.key
  chmod 0644 /etc/pcs-host-agent/tls/server.crt /etc/pcs-host-agent/tls/ca.crt
fi

install -o root -g root -m 0440 "$SRC_DIR/pcs-host-agent.sudoers" /etc/sudoers.d/pcs-host-agent
visudo -cf /etc/sudoers.d/pcs-host-agent >/dev/null
install -o root -g root -m 0644 "$SRC_DIR/pcs-host-agent.service" /etc/systemd/system/pcs-host-agent.service

systemctl daemon-reload
systemctl enable --now pcs-host-agent.service

sleep 1
systemctl is-active --quiet pcs-host-agent.service
curl --fail --silent --show-error --cacert /etc/pcs-host-agent/tls/ca.crt https://127.0.0.1:${PORT}/v1/health >/dev/null || {
  echo "local health check failed (certificate SAN may not contain 127.0.0.1); checking TLS listener" >&2
  ss -ltnp | grep -q ":${PORT} "
}

echo "PCS_HOST_AGENT_INSTALL_PASS"
echo "port=${PORT}"
echo "ca_sha256=$(sha256sum /etc/pcs-host-agent/tls/ca.crt | awk '{print $1}')"
echo "token_file=/etc/pcs-host-agent/auth.token"
echo "ca_file=/etc/pcs-host-agent/tls/ca.crt"
echo "NOTE: copy token and CA to the authorized client through a secure channel; never put either token value in Drive/Git."