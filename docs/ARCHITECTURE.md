# Architecture — Alpha Reference

PML uses a deterministic control plane around bounded model-based judgment.

## Layers

### Deterministic engine

The engine owns state transitions, claim accounting, reservations, integrity checks, retries/recovery, bounded archival, schedules, wake bookkeeping and role-scoped API operations.

### Deterministic runner

The Python runner performs bounded mechanical jobs such as page watches, feed scans, public job-board scans and context collection. External text is treated as untrusted data and cannot select authoritative policies or executable job names.

### Scheduled model workers

Scheduled model tasks perform bounded judgment and research. Their runtime reasoning effort must be treated as **unverified unless the platform exposes and verifies it**. Prompt text such as “HIGH” is not a capability boundary.

Queue routing therefore separates work difficulty from task labels:

- ordinary bounded work may be assigned to scheduled workers;
- work requiring reliably deeper reasoning is withheld from unverified scheduled workers and escalated for a verified/manual review lane.

### Manual high-reasoning controller

Architecture, security boundaries, scheduler design, canonical worker prompts and global strategic policy are handled in a human-supervised interactive session with an explicitly selected high reasoning mode.

This controller is outside the recurring worker topology. Scheduled agents may collect evidence and surface a review request, but they do not promote their own architectural proposals into policy.

## Role-scoped capabilities

The alpha engine defines distinct roles for operations, workers, deterministic jobs, guest intake and status-only monitoring. API credentials are role-scoped and hashed. Model quality is not used as an authorization primitive.

## Integrity model

The alpha implementation includes:

- immutable physical row identifiers;
- append-only claim accounting with a hash chain;
- strict observed-transition validation;
- row-level shadow state used as a write-intent record;
- idempotent deterministic-result commit plans;
- fixed trusted policies separated from untrusted external text;
- role-scoped credentials;
- bounded hot state with archive rotation;
- mechanical parsing and binding of result headers.

These mechanisms reduce accidental corruption and duplicate work. Direct spreadsheet editing remains an integrity-checked fallback rather than a cryptographically authenticated actor boundary.

## Review and escalation

The existing control-plane state and inbox are used for escalation; the design does not require a second review state machine. Operational controllers can surface architecture/security/prompt/strategy questions for manual high-reasoning review.

Periodic review should also examine worker-quality telemetry and whether fresh worker contexts/prompts should be created. Recycling workers is a control-plane maintenance action, not a scheduled worker privilege.

## Research-first architecture

Before adding a novel orchestration mechanism, review current official platform documentation, established software patterns, relevant open-source/technical work, credible practitioner failure reports, and local telemetry. Prefer the smallest reversible design that remains after that evidence pass.

## Public-source boundary

This repository contains only generic implementation material. Deployment-specific policy, state, identifiers, workflows and data belong outside source control.
