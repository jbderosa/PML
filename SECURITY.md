# Security Policy

## Status

PML is **alpha software**. It is under active security and reliability review and should not be treated as production-hardened.

## Sensitive information

Never include credentials, tokens, private URLs, personal data, or real deployment state in a public issue, pull request, test fixture, log excerpt, or code sample.

If a security report necessarily contains sensitive material, use a private GitHub security-reporting channel when available rather than a public issue.

## Design principles

The public reference implementation aims to:

- separate trusted instructions from untrusted external data;
- use least-privilege credentials and role-scoped capabilities;
- keep deterministic state transitions outside language-model judgment;
- make retries idempotent and observable;
- fail closed where ambiguity could create duplicate work or external side effects.

These are design goals, not a warranty of security.
