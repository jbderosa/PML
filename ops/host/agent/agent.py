#!/usr/bin/env python3
import hashlib
import hmac
import json
import os
import re
import ssl
import subprocess
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

LISTEN_HOST = os.environ.get('PCS_HOST_AGENT_HOST', '0.0.0.0')
LISTEN_PORT = int(os.environ.get('PCS_HOST_AGENT_PORT', '8443'))
TOKEN_FILE = Path(os.environ.get('PCS_HOST_AGENT_TOKEN_FILE', '/etc/pcs-host-agent/auth.token'))
CERT_FILE = os.environ.get('PCS_HOST_AGENT_CERT_FILE', '/etc/pcs-host-agent/tls/server.crt')
KEY_FILE = os.environ.get('PCS_HOST_AGENT_KEY_FILE', '/etc/pcs-host-agent/tls/server.key')
STATE_DIR = Path(os.environ.get('PCS_HOST_AGENT_STATE_DIR', '/var/lib/pcs-host-agent'))
RUNNER = os.environ.get('PCS_HOST_AGENT_RUNNER', '/usr/local/libexec/pcs-host-agent-runner')
MAX_BODY = 16 * 1024
REQUEST_ID_RE = re.compile(r'^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$')
OPS = {'status', 'verify_os', 'reboot', 'apply_os_security', 'install_kernel_virtual'}
OP_TIMEOUTS = {'status': 60, 'verify_os': 180, 'reboot': 60, 'apply_os_security': 900, 'install_kernel_virtual': 900}

STATE_DIR.mkdir(parents=True, exist_ok=True)
(STATE_DIR / 'requests').mkdir(parents=True, exist_ok=True)
(STATE_DIR / 'locks').mkdir(parents=True, exist_ok=True)


def _token() -> bytes:
    value = TOKEN_FILE.read_text(encoding='utf-8').strip()
    if len(value) < 32:
        raise RuntimeError('auth token too short')
    return value.encode('utf-8')


def _atomic_write(path: Path, obj: dict) -> None:
    tmp = path.with_suffix(path.suffix + '.tmp')
    payload = json.dumps(obj, sort_keys=True, separators=(',', ':')) + '\n'
    with open(tmp, 'x', encoding='utf-8') as f:
        f.write(payload)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)


def _request_hash(request_id: str) -> str:
    return hashlib.sha256(request_id.encode()).hexdigest()

def _record_path(request_id: str) -> Path:
    return STATE_DIR / 'requests' / (_request_hash(request_id) + '.json')

def _lock_path(request_id: str) -> Path:
    return STATE_DIR / 'locks' / (_request_hash(request_id) + '.json')


def _auth_ok(header: str | None) -> bool:
    if not header or not header.startswith('Bearer '):
        return False
    supplied = header[7:].strip().encode('utf-8')
    try:
        expected = _token()
    except Exception:
        return False
    return hmac.compare_digest(supplied, expected)


class Handler(BaseHTTPRequestHandler):
    server_version = 'pcs-host-agent/0.1'
    sys_version = ''

    def log_message(self, fmt, *args):
        # Do not emit auth headers or bodies. systemd still captures coarse request metadata.
        print('%s %s' % (self.address_string(), fmt % args), flush=True)

    def _json(self, code: int, obj: dict):
        body = (json.dumps(obj, sort_keys=True, separators=(',', ':')) + '\n').encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.end_headers()
        self.wfile.write(body)

    def _require_auth(self) -> bool:
        if _auth_ok(self.headers.get('Authorization')):
            return True
        self._json(401, {'ok': False, 'error': 'UNAUTHORIZED'})
        return False

    def do_GET(self):
        if self.path == '/v1/health':
            self._json(200, {'ok': True, 'service': 'pcs-host-agent', 'version': 1})
            return
        if self.path == '/v1/ops':
            if not self._require_auth():
                return
            self._json(200, {'ok': True, 'operations': sorted(OPS)})
            return
        self._json(404, {'ok': False, 'error': 'NOT_FOUND'})

    def do_POST(self):
        if self.path != '/v1/execute':
            self._json(404, {'ok': False, 'error': 'NOT_FOUND'})
            return
        if not self._require_auth():
            return
        try:
            length = int(self.headers.get('Content-Length', '0'))
        except ValueError:
            self._json(400, {'ok': False, 'error': 'BAD_LENGTH'})
            return
        if length <= 0 or length > MAX_BODY:
            self._json(413, {'ok': False, 'error': 'BAD_BODY_SIZE'})
            return
        try:
            body = json.loads(self.rfile.read(length).decode('utf-8'))
        except Exception:
            self._json(400, {'ok': False, 'error': 'BAD_JSON'})
            return
        if not isinstance(body, dict) or set(body) - {'op', 'request_id'}:
            self._json(400, {'ok': False, 'error': 'BAD_REQUEST_SHAPE'})
            return
        op = body.get('op')
        request_id = body.get('request_id')
        if op not in OPS:
            self._json(400, {'ok': False, 'error': 'OP_NOT_ALLOWED'})
            return
        if not isinstance(request_id, str) or not REQUEST_ID_RE.fullmatch(request_id):
            self._json(400, {'ok': False, 'error': 'BAD_REQUEST_ID'})
            return

        rp = _record_path(request_id)
        lp = _lock_path(request_id)
        if rp.exists():
            try:
                prior = json.loads(rp.read_text(encoding='utf-8'))
            except Exception:
                self._json(500, {'ok': False, 'error': 'IDEMPOTENCY_RECORD_CORRUPT'})
                return
            if prior.get('op') != op or prior.get('request_id') != request_id:
                self._json(409, {'ok': False, 'error': 'IDEMPOTENCY_CONFLICT'})
                return
            self._json(200, prior)
            return

        lock_obj = {'op': op, 'request_id': request_id, 'locked_unix': int(time.time())}
        try:
            _atomic_write(lp, lock_obj)
        except FileExistsError:
            self._json(409, {'ok': False, 'error': 'REQUEST_IN_PROGRESS_OR_INTERRUPTED', 'op': op, 'request_id': request_id})
            return

        started = int(time.time())
        try:
            cp = subprocess.run(
                ['sudo', '-n', RUNNER, op, request_id],
                text=True,
                capture_output=True,
                timeout=OP_TIMEOUTS[op],
                check=False,
                env={'PATH': '/usr/sbin:/usr/bin:/sbin:/bin'},
            )
            stdout = cp.stdout[-32768:]
            stderr = cp.stderr[-8192:]
            result = {
                'ok': cp.returncode == 0,
                'op': op,
                'request_id': request_id,
                'started_unix': started,
                'finished_unix': int(time.time()),
                'exit_code': cp.returncode,
                'stdout': stdout,
                'stderr': stderr,
            }
        except subprocess.TimeoutExpired:
            result = {
                'ok': False,
                'op': op,
                'request_id': request_id,
                'started_unix': started,
                'finished_unix': int(time.time()),
                'error': 'RUNNER_TIMEOUT',
            }
        except Exception as e:
            result = {
                'ok': False,
                'op': op,
                'request_id': request_id,
                'started_unix': started,
                'finished_unix': int(time.time()),
                'error': 'RUNNER_ERROR',
                'detail': type(e).__name__,
            }
        try:
            _atomic_write(rp, result)
        except FileExistsError:
            prior = json.loads(rp.read_text(encoding='utf-8'))
            self._json(200, prior)
            return
        finally:
            try:
                lp.unlink()
            except FileNotFoundError:
                pass
        self._json(200 if result.get('ok') else 500, result)


def main():
    httpd = ThreadingHTTPServer((LISTEN_HOST, LISTEN_PORT), Handler)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.minimum_version = ssl.TLSVersion.TLSv1_2
    ctx.load_cert_chain(certfile=CERT_FILE, keyfile=KEY_FILE)
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
    httpd.serve_forever()


if __name__ == '__main__':
    main()