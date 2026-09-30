#!/usr/bin/env bash
set -euo pipefail
for f in agent.py runner.sh install.sh; do
  [[ -s "$f" ]]
done
python3 -m py_compile agent.py
bash -n runner.sh
bash -n install.sh
grep -q "OPS = {'status', 'verify_os', 'reboot', 'apply_os_security', 'install_kernel_virtual'}" agent.py
grep -q 'operation not allowed' runner.sh
grep -q '/usr/local/libexec/pcs-host-agent-runner status \*' pcs-host-agent.sudoers
echo PCS_HOST_AGENT_CHECK_PASS