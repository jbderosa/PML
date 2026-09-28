# PML Control Plane — 2.6 Alpha Public Reference

> **ALPHA SOFTWARE — experimental, incomplete, and not production-ready.**
>
> This public repository is a privacy-preserving reference projection of an actively reviewed control-plane prototype. It is not canonical deployment state and is intentionally not byte-for-byte identical to any private deployment bundle.

PML separates work into three layers:

1. **deterministic orchestration** — state transitions, locking, reservations, integrity checks, retries and archival;
2. **deterministic jobs** — bounded fetch/filter/dedupe/diff work in Python;
3. **model workers** — judgment tasks that cannot be reduced to deterministic code.

## Alpha status

The 2.6 implementation has undergone a code-level adversarial review. Major integrity mechanisms work in synthetic tests, but real-platform validation remains required and several reproducible alpha defects remain. See [`docs/ALPHA_AUDIT.md`](docs/ALPHA_AUDIT.md).

## Privacy boundary

Only generic, rewritten documentation and deliberately inactive examples are published directly in this repository at this stage. Real deployment state, personal workflows, identifiers, credentials, URLs, result artifacts and logs do not belong here.

The reviewed source has also been sanitized into a separate alpha bundle, but it is **not installed as an active GitHub Actions deployment** and this repository does not currently claim to be a production-ready source release.

See [`PUBLICATION_POLICY.md`](PUBLICATION_POLICY.md) and [`SANITIZATION.md`](SANITIZATION.md).

## Currently published here

| Path | Purpose |
|---|---|
| `docs/ARCHITECTURE.md` | generic architecture summary |
| `docs/ALPHA_AUDIT.md` | independent audit status and reproduced limitations |
| `examples/pml-runner.workflow.yml` | **inactive example** workflow; not installed under `.github/workflows/` |
| `tools/runner_usage_model.py` | generic runner-use/cost model |
| `PUBLICATION_POLICY.md` | privacy-preserving publication rules |
| `SECURITY.md` | alpha security notice |
| `SANITIZATION.md` | differences applied to the public projection |
| `VERSION` | public alpha version |

## Deployment warning

Do not copy private configuration or state into this repository. In particular, do not commit API URLs, credentials, account/resource IDs, personal watchlists, real queue items, result documents, or production logs.

The runner workflow is intentionally published only as an example. Merely cloning this repository should not start a scheduler or create operational logs.
