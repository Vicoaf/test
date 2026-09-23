# PROXTEL Development Git Policy

## Default

Git is local-first.

Do not create commits automatically unless explicitly instructed.

Do not push automatically unless explicitly instructed.

## Before changes

Inspect branch, status and relevant project instructions.

Do not assume an uncommitted working tree is disposable.

## During work

Keep changes scoped to the authorized task.

Do not use reset/clean/checkout operations that discard user work without explicit authorization.

## Before release-ready

Review diff.

Run git diff --check when available.

Verify no secrets, .env files, credentials, private keys, production dumps, recordings, node_modules, vendor, caches or logs are being introduced unintentionally.

## Commit

Commit and push are separate explicit actions.

When requested, create focused commits with descriptive messages.