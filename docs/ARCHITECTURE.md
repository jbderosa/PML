# Architecture — Alpha Reference

PML uses a deterministic control plane around model-based workers.

## Layers

### Engine

The engine owns state transitions, claim accounting, reservations, mechanical result checks, retry/recovery, bounded archival, wake bookkeeping and role-scoped API operations. The current adapter targets Google Sheets/Apps Script, while the engine is designed around a storage interface rather than Sheet-specific business logic.

### Deterministic runner

The Python runner performs bounded mechanical jobs such as page watches, feed scans, public job-board scans and context collection. External text is treated as untrusted data and cannot select authoritative policies or executable job names.

### Model workers

Workers execute bounded judgment units. They do not own global scheduling or priority policy. Results are mechanically bound to the claimed row before semantic review.

## Integrity model

The alpha implementation includes:

- immutable physical row identifiers;
- append-only claim accounting with a hash chain;
- strict observed transition validation;
- row-level shadow state used as a write-intent record;
- idempotent deterministic-result commit plans;
- fixed trusted policies separated from untrusted external text;
- role-scoped credentials stored as hashes;
- bounded hot state with archive rotation;
- mechanical parsing and binding of result headers.

These mechanisms reduce accidental corruption and duplicate work. They are not a substitute for a hostile multi-tenant security boundary: a deployment should still minimize who can edit its underlying storage and protect all credentials independently.

## Public-source boundary

The public repository contains generic implementation material only. Deployment-specific policy, configuration, state and data belong outside source control.
