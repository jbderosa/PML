#!/usr/bin/env bash
# Local gate for host scripts. Run before every commit that touches ops/host:
#   bash ops/host/check.sh
# GitHub Actions does not run on this account, so this is the only gate.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here"
failures=0
fail(){ printf 'GATE FAIL: %s\n' "$*" >&2; failures=$((failures + 1)); }
ok(){ printf 'ok: %s\n' "$*"; }

scripts=()
for f in ./*.sh; do scripts+=("$f"); done

# 1. Every script parses.
for f in "${scripts[@]}"; do
  if bash -n "$f"; then ok "bash -n $f"; else fail "bash -n $f"; fi
done

# 2. shellcheck at warning level (required, not optional).
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -S warning "${scripts[@]}"; then ok "shellcheck -S warning"; else fail "shellcheck"; fi
else
  fail "shellcheck is not installed"
fi

# 3. The verifier prints its PASS marker exactly once, as its last statement.
verifier=./11-verify-os-security.sh
marker=ARCHITECT_OS_FOUNDATION_VERIFY_PASS
count="$(grep -c "$marker" "$verifier" || true)"
last="$(awk 'NF {line=$0} END {print line}' "$verifier")"
if [[ "$count" == "1" && "$last" == *"$marker"* ]]; then
  ok "$marker appears once, on the last line"
else
  fail "$marker appears $count times; last line is: $last"
fi

# 4. UFW parser tests against fixtures in real ufw 0.36.2 (Ubuntu 24.04) format.
#    pass-* must be accepted for port 22; fail-* must be rejected.
# shellcheck source=11-verify-os-security.sh
VERIFY_LIB_ONLY=1 source "$verifier"
set +e
for fx in tests/ufw-fixtures/*.txt; do
  name="$(basename "$fx")"
  ufw_ssh_only 22 <"$fx" 2>/dev/null
  rc=$?
  case "$name" in
    pass-*) [[ $rc -eq 0 ]] && ok "parser accepts $name" || fail "parser rejected $name" ;;
    fail-*) [[ $rc -ne 0 ]] && ok "parser rejects $name" || fail "parser accepted $name" ;;
    *) fail "fixture $name must start with pass- or fail-" ;;
  esac
done
set -e

if [[ $failures -ne 0 ]]; then
  printf 'HOST_SCRIPTS_GATE_FAIL (%s)\n' "$failures"
  exit 1
fi
printf 'HOST_SCRIPTS_GATE_PASS\n'