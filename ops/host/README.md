# Shared host bootstrap sequence

These scripts are intentionally small Architect-owned migration milestones. Do not collapse them into a single unattended bootstrap. PIL and PML remain separate application authority domains even though the Architect owns the shared host.

## 00-baseline.sh

Read-only. Capture the minimum host facts needed to prove that the intended host is being changed and to discover pre-existing state.

Review the output before running any mutating script.

## 10-os-security.sh

Mutating OS/privacy foundation. Run only after key-only SSH works and the baseline has been reviewed.

The script fails closed if disk-backed swap is active or configured. It then:

- installs Ubuntu-supported UFW, zram-tools, and unattended-upgrades;
- configures zram-only swap at 50% of RAM;
- disables Apport/core-memory persistence and installs a discard core-pattern;
- creates separate non-login PML, PIL, and coordinator service identities;
- creates root-owned app paths plus service-private state/artifact paths matching the shared migration contract;
- creates root-controlled configuration directories and service-specific runtime secret directories beneath memory-backed /run;
- keeps SSH public-key authentication enabled while disabling password and keyboard-interactive SSH;
- preserves Ubuntu 24.04 socket-activated OpenSSH and permits only its detected port through UFW;
- enables daily unattended security updates without automatic reboot.

It does **not** install PostgreSQL, Docker, application services, Claude access, production credentials, or migration data.

## Acceptance after 10-os-security.sh

Checkpoint before continuing. Verify:

1. the host identity matches the intended Droplet;
2. every active swap target is /dev/zram* and no disk swap is configured;
3. /run resolves to tmpfs or ramfs;
4. the existing root session remains open while a second independent key-only SSH login succeeds after firewall/SSH reload;
5. UFW denies unsolicited inbound traffic except the intended SSH port;
6. PML, PIL, and coordinator identities are non-login and separate;
7. /srv/{pml,pil,coord}/app is deployment-controlled while state/artifacts are private to the matching service identity;
8. ordinary core-dump/Apport persistence is disabled and kernel.core_pattern discards cores;
9. no application secrets or personal data were introduced.

Run `11-verify-os-security.sh` after the mutating script and after proving a second independent key-only SSH login. The next milestone may install the container/runtime layer only after that verifier prints `ARCHITECT_OS_FOUNDATION_VERIFY_PASS`.
