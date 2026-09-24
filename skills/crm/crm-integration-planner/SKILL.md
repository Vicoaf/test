---
name: crm-integration-planner
description: Specify CRM telephony, REST, webhook and external-system contracts with explicit authentication, idempotency and observability boundaries.
---

# CRM Integration Planner

## Purpose

Specify CRM telephony, REST, webhook and external-system contracts with explicit authentication, idempotency and observability boundaries.

## Use when

- CRM integrates with telephony
- webhooks or APIs are involved
- external side effects require a contract

## Method

1. Gather evidence before recommendations.
2. Separate verified facts from assumptions and open decisions.
3. Define the smallest CRM-domain contract needed for the requested change.
4. Preserve privacy, authorization and auditability boundaries.
5. Delegate repository implementation to the Development area when code changes are required.
6. Return deterministic acceptance criteria and known limitations.

## Safety

- Read-only discovery first.
- No production or database mutation by default.
- No secret exposure.
- No automatic dependency installation.
- No automatic Git add, commit, push or deployment.
- No automatic retry of consumed external side effects.

## Outputs

- integration contract
- data flow
- authentication boundary
- error/retry semantics
- observability requirements
