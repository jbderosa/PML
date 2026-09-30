#!/usr/bin/env bash
set -euo pipefail

for f in agent.py runner.sh install.sh pcs-host-agent.service pcs-host-agent.sudoers; do
  [[ -s "$f" ]]
done

python3 -m py_compile agent.py
bash -n runner.sh
bash -n install.sh

# Fixed operation surface only; callers may provide only op + request_id.
grep -q "OPS = {'status', 'verify_os', 'reboot', 'apply_os_security', 'install_kernel_virtual'}" agent.py
grep -Fq "set(body) - {'op', 'request_id'}" agent.py
grep -q 'operation not allowed' runner.sh
grep -q '/usr/local/libexec/pcs-host-agent-runner status \*' pcs-host-agent.sudoers
! grep -Eq "body\.get\('(exec|shell|script|path|args)'\)" agent.py

# Host-foundation coordinator identity is coordsvc everywhere deployable.
grep -q '^User=coordsvc$' pcs-host-agent.service
grep -q '^Group=coordsvc$' pcs-host-agent.service
grep -q '^coordsvc ALL=' pcs-host-agent.sudoers
grep -q 'id coordsvc ' install.sh
! grep -n 'coord-svc' agent.py install.sh pcs-host-agent.service pcs-host-agent.sudoers >/dev/null

# Management endpoint is loopback-only by default and installer opens no UFW port.
grep -Fq "LISTEN_HOST = os.environ.get('PCS_HOST_AGENT_HOST', '127.0.0.1')" agent.py
! grep -Fq "LISTEN_HOST = os.environ.get('PCS_HOST_AGENT_HOST', '0.0.0.0')" agent.py
! grep -Eq 'ufw[[:space:]]+(allow|limit)[[:space:]]' install.sh

echo PCS_HOST_AGENT_CHECK_PASS
