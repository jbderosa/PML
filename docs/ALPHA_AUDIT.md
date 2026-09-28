# Alpha audit status — 2.6 public reference

This code remains **alpha**. A code-level re-audit found major improvements over earlier prototypes, including working append-only claim accounting, crash-recoverable deterministic commits, strict result parsing, prompt-injection separation, SSRF defenses, bounded archival and credential hardening.

## Independently exercised

On the reviewed 2.6 bundle:

- Python runner: **44/44 tests passed**.
- Claim-ledger tests: **10/10 passed**.
- Injection-boundary tests: **11/11 passed**.
- Mechanical-check tests: **20/20 passed**.
- Deterministic-commit tests: **11/11 passed**.
- Security/quota tests: **11/11 passed**.
- Apps Script adapter mock tests: **5/5 passed**.
- Lifecycle scenarios were exercised individually and passed, including private/public runner budgeting, event doorbells, heartbeats and claim/delivery cycles.
- The 30-day bounded-growth simulation reports flat live-state/read metrics and its assertions pass.

The full combined JavaScript invocation was not treated as a clean pass because some heavy test files report successful TAP completion but leave the Node process alive long enough to hit the surrounding command timeout. That harness-termination behavior should be fixed before CI is considered authoritative. The 90-day simulation has not been independently re-run in this public audit pass.

## Reproduced known issues

### 1. Private-runner dispatch budget does not age out

`runner_dispatch_billed_30d` is incremented as a lifetime counter. After a private deployment reaches its dispatch allocation, advancing beyond 30 days still leaves the deployment in `BUDGET_HOLD` even though the rolling `runner_runs` usage has aged out.

A future patch should compute dispatch use from the same rolling-window run records rather than a monotonic counter.

### 2. Direct-sheet attempt jumps can manufacture claim usage

The reconciler interprets an increase in a row's `attempt` field as previously unseen claims. A direct edit from `0` to a large value can therefore append many synthetic claim events and force the global claim cap into a hold state.

A future patch should reject/quarantine implausible jumps (normally delta `1`) rather than converting an arbitrary jump into many ledger entries.

### 3. MailApp recipient is not a hard-coded capability boundary

The MailApp path validates the wake subject, but the recipient comes from mutable Sheet configuration. If a strict "only this recipient" invariant is required, the allowed recipient should be held outside agent-editable state (for example, a protected Script Property) and checked again at the send boundary.

### 4. Public Actions reveal operational metadata

Even with sanitized logs, workflow run timing is public in a public GitHub repository. This repository therefore publishes the runner workflow only as an **inactive example**. Operators should make an explicit privacy/cost decision before using public Actions for a real deployment.

## Platform validation still required

Synthetic tests cannot establish the behavior of unattended model tasks, connector writes, Apps Script quotas, event-trigger merging, or real Google Sheets formula/text behavior. Those are deployment-gating checks, not assumptions.


## Live platform smoke test

A live alpha smoke test has now exercised the core model-worker path on the target platform:

- the bound deterministic reconciler ran on schedule;
- a synthetic, no-external-effect work item was validated and reserved;
- a scheduled worker claimed exactly once;
- the append-only claim ledger recorded the claim;
- the worker created and delivered the required result artifact;
- mechanical result validation passed;
- the Executive reviewed and accepted the result;
- the control plane transitioned from STEP to CONTINUOUS and the next reconcile reflected that mode.

One platform quirk was observed: direct creation of a native Doc into the configured results folder was not supported by the connected OAuth/delegated Drive path used by the worker, so the worker created the Doc and moved it into the configured folder before delivery. Final folder placement was independently verified and the engine's mechanical check correctly passed.

This validates the core agent/reconciler path only. It does not yet validate the deterministic Python runner, deployed HTTP API, event-doorbell path, or sustained production workload.
