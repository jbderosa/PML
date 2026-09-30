# PCS narrow host-control API

This is a bootstrap/operations bridge for agents that cannot retain SSH access. It is deliberately **not** a remote shell.

## Security model

- HTTPS only; bootstrap generates a local CA and server certificate.
- 256-bit bearer token generated on-host; token value is never committed.
- API runs as `coord-svc`, not root.
- Root authority is reachable only through one exact sudo runner.
- Runner accepts a fixed operation allowlist; the caller supplies no shell text, file paths, package names, service names, or command arguments.
- Per-request idempotency records prevent accidental replay of the same request id.
- API request bodies and authorization headers are not logged.
- Real deployment addresses, credentials and logs remain outside Git.

Initial operations:

| Operation | Effect |
|---|---|
| `status` | Return kernel, uptime, swap and UFW status. |
| `verify_os` | Run the reviewed OS-foundation verifier installed at bootstrap. |
| `apply_os_security` | Re-run the reviewed, fixed OS/privacy hardening script. |
| `install_kernel_virtual` | Install the fixed Ubuntu virtual-kernel package set and fail unless the newest installed kernel contains zram. |
| `reboot` | Schedule a delayed reboot through systemd. |

The two mutating maintenance operations above are fixed programs with no caller-supplied package names or paths. Adding any other privileged capability requires a reviewed code change to both the API allowlist and root-owned runner/sudoers. Do not add a generic `exec`, `shell`, `script`, `path`, or caller-supplied `args` operation.

## API

Unauthenticated liveness:

`GET /v1/health`

Authenticated operation list:

`GET /v1/ops`

Execute:

```json
{"op":"status","request_id":"claude-20260930-status-001"}
```

Send to `POST /v1/execute` with `Authorization: Bearer <token>`.

## Bootstrap

Run the reviewed host foundation first so `coord-svc` exists. Then, from this directory as root:

```sh
./check.sh
./install.sh
```

The installer prints only paths and the CA fingerprint. Transfer `/etc/pcs-host-agent/auth.token` and `/etc/pcs-host-agent/tls/ca.crt` to the authorized client through a secure channel. Do not put the token value into Drive, Git, logs, chat, or command history.

Example client call after securely obtaining the token and CA:

```sh
curl --cacert ./ca.crt \
  -H "Authorization: Bearer $PCS_HOST_AGENT_TOKEN" \
  -H 'Content-Type: application/json' \
  --data '{"op":"status","request_id":"claude-20260930-status-001"}' \
  https://HOST:8443/v1/execute
```

A production follow-up should move public ingress behind a durable identity-aware gateway or mTLS if/when one is available. This first version is intentionally small and reversible.