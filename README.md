# PML Control Plane — 2.6 Alpha Public Reference

> **ALPHA SOFTWARE — experimental, incomplete, and not production-ready.**
>
> This public tree is a privacy-preserving reference projection of an actively reviewed control-plane prototype. It is not canonical deployment state, and it is intentionally not byte-for-byte identical to any private deployment bundle.

PML separates work into three layers:

1. **deterministic orchestration** — state transitions, locking, reservations, integrity checks, retries and archival;
2. **deterministic jobs** — bounded fetch/filter/dedupe/diff work in Python;
3. **model workers** — judgment tasks that cannot be reduced to deterministic code.

## Alpha status

The design has extensive synthetic tests, but real-platform validation is still required before unattended deployment. Known issues and independently reproduced findings are tracked in [`docs/ALPHA_AUDIT.md`](docs/ALPHA_AUDIT.md).

## Privacy boundary

Only generic code, schemas, synthetic tests and rewritten documentation are published here. Real deployment state, personal workflows, identifiers, credentials, URLs, result artifacts and logs do not belong in this repository.

See [`PUBLICATION_POLICY.md`](PUBLICATION_POLICY.md) and [`SANITIZATION.md`](SANITIZATION.md).

## Layout

| Path | Purpose |
|---|---|
| `src/` | storage-agnostic core, engine, and Google Apps Script adapter |
| `runner/pml_runner/` | deterministic Python runner and network policy |
| `runner/tests/` | Python tests using synthetic fixtures |
| `test/` | JavaScript engine and adapter tests |
| `tools/runner_usage_model.py` | runner-use model |
| `examples/pml-runner.workflow.yml` | **inactive example** workflow; copy only after configuring a deployment |
| `docs/ARCHITECTURE.md` | generic architecture summary |
| `docs/ALPHA_AUDIT.md` | audit status and known limitations |

## Tests

```sh
# JavaScript test files can be run individually
node --test test/claims_ledger.test.js
node --test test/injection.test.js
node --test test/mech_check.test.js
node --test test/py_commit.test.js
node --test test/security_quota.test.js
node --test test/sheetstore.test.js
node --test test/growth.test.js

# Python
cd runner
python -m pytest tests
```

The long-horizon simulation is intentionally separate:

```sh
node --test test/long/growth90.test.js
```

## Deployment warning

Do not copy private configuration or state into this repository. In particular, do not commit API URLs, credentials, account/resource IDs, personal watchlists, real queue items, result documents, or production logs.

The example workflow is intentionally not installed under `.github/workflows/`; publishing this source repository should not start a live scheduler.
