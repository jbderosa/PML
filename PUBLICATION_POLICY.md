# Public Publication Policy

This repository is a public, generic projection of the PML control-plane project.

## Release classification

All current material is **ALPHA** unless a later release explicitly says otherwise.

Alpha means:

- behavior and interfaces may change;
- tests do not substitute for real-platform validation;
- deployment assumptions may still be wrong;
- unattended production use is not recommended.

## What may be published

Publish only material that is reusable without knowing who operates a deployment:

- source code and schemas;
- deterministic tests and synthetic fixtures;
- generic architecture documentation;
- generic threat models and security controls;
- generic deployment instructions using placeholders;
- benchmark results produced from synthetic data.

## What must stay private

Do not publish deployment state or data tied to a real person, organization, account, workflow, or resource.

Before publication, remove or replace:

- names, contact details, addresses, account identifiers, document IDs, folder IDs, task IDs, repository secrets, tokens, credentials, and private URLs;
- personal queue items, inbox messages, result documents, logs, state snapshots, migration journals, watchlists, schedules, and target lists;
- examples that reveal health, finances, employment, housing, relationships, communications, travel, or other personal activity;
- operational details that disclose a private deployment's current state or security material.

## Sanitization rules

Public examples should use synthetic fixtures and reserved/example values. Prefer:

- `example.invalid` for email/domain examples where possible;
- neutral labels such as `EXAMPLE_USER` and `EXAMPLE_WORKFLOW`;
- random synthetic IDs that are not derived from real IDs;
- fabricated timestamps and content.

Do not merely redact a few characters from a real identifier. Replace the whole value.

## Review requirement

Before any file from a private working environment is published, review it for:

1. personal or identifying information;
2. secrets and credentials;
3. private resource identifiers and URLs;
4. deployment-specific state or workflow content;
5. comments, tests, fixtures, and logs that indirectly reveal any of the above.

When uncertain, keep the material private and publish a generic rewrite instead.
