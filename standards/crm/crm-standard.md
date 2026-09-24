# PROXTEL CRM Standard v1.0

## Domain-first

CRM changes must start from actors, roles, records, lifecycle states, ownership and business rules.

## Authorization

Every sensitive CRM action must have an explicit authorization boundary. UI visibility alone is not authorization.

## Data and imports

Imports require explicit field mapping, validation, duplicate handling, rejection behavior and dry-run acceptance criteria before mutation. PII must be minimized in artifacts.

## Workflows

State transitions, assignment rules, tasks and automations must be deterministic. External side effects should be observable and idempotent where practical.

## Integrations

Telephony, REST and webhooks require defined authentication boundaries, payload contracts, failure behavior and observability. Secrets must not be stored in repository artifacts.

## Implementation

CRM-domain artifacts do not replace Development implementation governance. Repository code changes are delegated to `proxtel-development-orchestrator`.

## Release

Release readiness requires both technical validation and CRM-domain validation. Commit, push and deployment remain explicit user-authorized actions.
