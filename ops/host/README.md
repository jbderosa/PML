# Host bootstrap sequence

These scripts are intentionally small migration milestones. Do not collapse them into a single unattended bootstrap.

## 00-baseline.sh

Read-only. Capture the minimum host facts needed to prove that the intended host is being changed and to discover pre-existing state.

Review the output before running any mutating script.

## 10-os-security.sh

Mutating OS/privacy foundation. Run only after key-only SSH works and the baseline has been reviewed.

The script fails closed if disk-backed swap is active or configured. It then:

- installs Ubuntu-supported UFW, zram-tools, and unattended-upgrades;
- configures zram-only swap at 50% of RAM;
- disables ordinary core-dump persistence;
- creates separate non-login PML, PIL, and coordinator service identities;
- creates root-controlled configuration directories and service-owned data/work directories;
- creates service-specific runtime secret directories beneath memory-backed /run;
- keeps SSH public-key authentication enabled while disabling password and keyboard-interactive SSH;
- permits only the detected SSH port through UFW;
- enables daily unattended security updates without automatic reboot.

It does **not** install PostgreSQL, Docker, application services, Claude access, production credentials, or migration data.

## Acceptance after 10-os-security.sh

Checkpoint before continuing. Verify:

1. the host identity matches the intended Droplet;
2. every active swap target is /dev/zram* and no disk swap is configured;
3. /run resolves to tmpfs or ramfs;
4. SSH remains reachable by key after the firewall/reload;
5. UFW denies unsolicited inbound traffic except the intended SSH port;
6. PML, PIL, and coordinator service identities/directories are separate;
7. ordinary core-dump persistence is disabled;
8. no application secrets or personal data were introduced.

The next milestone may install the container/runtime layer only after these checks pass.
