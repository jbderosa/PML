# PML v2.8 VPS Shadow Migration Foundation

Status: implementation candidate. This branch is non-authoritative and must not be used as a production cutover source until parity and recovery gates pass.

## Authority invariant

The existing production control plane remains the sole canonical writer during shadow migration. A VPS/PostgreSQL deployment may import, replay, and compare state, but it must not mutate production authority until an explicit cutover disables the old writer first.

Never operate two canonical writers concurrently.

## First implementation target

The first target is a read-only shadow that can:

1. import every active and archive control-plane table;
2. preserve semantic IDs, row versions, packet/result nonces, provenance, privacy classification, idempotency and dedupe fields;
3. verify append-only claim and event hash chains;
4. compute deterministic comparison digests;
5. replay frozen state-machine inputs against the migrated engine;
6. report parity without affecting production state.

Worker transport, administrative approval, and canonical cutover are later milestones.

## Schema migration rule

Port behavior before refactoring. Preserve current logical table boundaries for the first PostgreSQL migration.

Archive tables remain separate in the first migration when they are separate in the source. Consolidation or partitioning is a later reviewed optimization.

Use JSONB only for fields that are structurally JSON in the source contract. Free text remains text.

Use explicit primary keys matching the source semantic identifiers. Preserve row-version and nonce fences exactly.

## Transaction and integrity requirements

State transitions that span multiple source writes must become one PostgreSQL transaction.

Claims and events are append-only ledgers. Application roles must not be able to update or delete accepted ledger rows.

Canonical reconciliation remains single-writer even if the database can support more concurrency.

Use row-version checks and database constraints so stale command application fails closed.

## Privacy and encryption requirements

Public source control contains only generic schemas, code, synthetic fixtures, and documentation. Real deployment identifiers, personal data, live state, logs, URLs, credentials, migration snapshots, and result artifacts must remain outside the repository.

Persisted personal information must be application-encrypted before production cutover. Service keys are separate by trust domain and must not be stored in Git, ordinary logs, packet/result payloads, database tables in plaintext, or backup archives.

Swap must be encrypted. Logs and crash dumps must not contain plaintext personal information. Off-host backups must be encrypted before leaving the host.

## Trust domains

PML, PIL, and any coordination service remain separate trust domains.

- PML owns PML queue/control state.
- PIL owns people, consent, sharing, and visibility state.
- Coordination is a broker only.

No service receives direct write access to another service's authoritative datastore. Cross-service requests use narrow authenticated interfaces with minimum necessary metadata and explicit idempotency.

## Acceptance gates for shadow migration

A shadow milestone is not complete until:

- every expected table is present;
- source and imported row counts match;
- canonical per-table digests match;
- claim and event chains verify to the recorded source heads;
- restart does not lose or duplicate imported state;
- malformed, stale, duplicate, and unauthorized writes fail closed;
- backup restore reproduces the same counts, chain heads, and canonical digest;
- the shadow remains unable to become a production writer accidentally.

## Rollback posture

The production source remains unchanged and readable throughout shadow migration. No migration milestone deletes or rewrites rollback evidence.
