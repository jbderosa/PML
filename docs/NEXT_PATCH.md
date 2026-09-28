# Next hardening pass — 2.7 candidates

This is a generic engineering note for the **alpha** reference implementation. It contains no deployment-specific state.

## Reproduced issues to fix before production use

### 1. Make the private-runner budget genuinely rolling

The engine calculates total runner usage from the last 30 days, but also maintains a monotonic dispatch-minute counter. That counter does not age out, so a private deployment can remain in `BUDGET_HOLD` after old usage has left the rolling window.

**Patch:** derive dispatch usage from timestamped `runner_runs` records in the same rolling window and remove the lifetime-style counter.

**Regression:** exhaust dispatch allocation, advance more than 30 days, and prove capacity returns as old dispatch runs age out.

### 2. Reject implausible direct-Sheet attempt jumps

The reconciler uses a monotonic `attempt` field to recover claims that occurred between reconciliation passes. An arbitrary direct edit from attempt N to N+k currently materializes k claim events.

That protects against under-counting, but it also lets one malformed/tampered row manufacture enough claims to trip a global safety cap.

**Patch:** a directly observed attempt delta greater than the allowed transition (normally 1) should fail closed with an integrity hold/revert; do not synthesize an arbitrary number of claims.

**Regression:** attempt 0→1 is recoverable; attempt 0→2+ is quarantined and cannot consume global claim allowance.

### 3. Hard-lock the MailApp recipient outside mutable state

Wake subjects are validated, but the MailApp destination is supplied by mutable configuration.

**Patch:** keep the allowed recipient in operator-controlled Script Properties (or an equivalent non-agent-editable capability boundary) and require exact equality again at the send boundary. Sheet configuration may request a wake; it should not choose the destination.

### 4. Treat public runner metadata as public

A public Actions repository makes run timing and public workflow metadata observable. Public runner logs must therefore contain only coarse counters and error classes—never personal data, target URLs, work descriptions, row/work identifiers, or deployment state.

The public reference repository keeps the workflow as an inactive example for this reason.

### 5. Make the test harness terminate cleanly

Several heavy JavaScript suites report successful TAP completion but keep the Node process alive long enough to hit an outer timeout. The 90-day simulation also could not be independently completed within a 12-minute audit window.

**Patch:** find and close leaked handles/timers/servers; make ordinary CI finish deterministically. Keep the long-horizon simulation in a separate job with explicit runtime/resource bounds.

### 6. Real-platform validation remains a gate

Before unattended deployment, independently verify the actual platform behavior relied upon by the design:

- unattended task reads/writes through the connected storage surface;
- event-trigger latency/coalescing;
- maximum useful task-run duration;
- real Sheets text/formula escaping behavior;
- Apps Script quota behavior;
- archive lookup latency at intended hot-state size.

Synthetic tests should remain necessary but not sufficient.
