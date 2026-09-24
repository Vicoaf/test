---
name: crm-requirements-auditor
description: Audit CRM requirements, actors, roles, record lifecycles and business rules from available evidence before implementation.
---

# CRM Requirements Auditor

## Purpose

Audit CRM requirements, actors, roles, record lifecycles and business rules from available evidence before implementation.

## Use when

- starting or changing CRM functionality
- requirements are incomplete
- roles or lifecycle behavior must be clarified

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

- verified requirements
- role matrix intent
- lifecycle map
- open decisions
- implementation handoff
