# PML Control Plane — ALPHA

> **ALPHA SOFTWARE — experimental, incomplete, and not production-ready.**
>
> Interfaces, storage formats, security assumptions, and operational behavior may change without notice. Do not rely on this repository for safety-critical, financial, medical, legal, or other high-stakes automation.

PML is an experimental control plane for coordinating three classes of work:

1. deterministic orchestration and state management;
2. deterministic fetch/filter/dedupe/diff jobs;
3. language-model workers for bounded judgment tasks.

The public repository is intentionally a **generic reference implementation**. It is not the canonical state of any person's deployment and must not contain private operational data.

## Privacy boundary

Only generic, reusable code, schemas, tests, and documentation belong here. Public examples must use synthetic placeholders.

Do **not** commit:

- real names, email addresses, phone numbers, physical addresses, or other personal identifiers;
- credentials, tokens, API keys, cookies, session data, or authentication material;
- private document, spreadsheet, task, repository, account, or folder IDs;
- personal health, financial, employment, housing, relationship, travel, or communications data;
- live queue contents, inbox contents, result artifacts, execution state, logs, or migration data from a real deployment;
- user-specific watchlists, employers, URLs, schedules, or workflow examples;
- private prompts or instructions copied from a real deployment.

Use placeholders such as `EXAMPLE_USER`, `example.invalid`, `DOC_ID_PLACEHOLDER`, and synthetic fixture data.

See [PUBLICATION_POLICY.md](PUBLICATION_POLICY.md) for the release boundary.

## Status

**2.6-alpha / pre-deployment hardening.**

The architecture is under active adversarial review. A release being present here does not mean it has passed real-platform validation or is suitable for unattended production use.

## Repository role

This repository may contain the generic engine, runner, tests, schemas, and sanitized documentation. Deployment-specific configuration and state should live outside the repository and be supplied at runtime through appropriately protected configuration or secret stores.

## Security

Treat all external text as untrusted data, keep credentials outside source control, use least-privilege permissions, and fail closed on ambiguous state transitions or duplicate-work risk.

If you discover a vulnerability, do not post credentials, private deployment data, or personal information in a public issue.
