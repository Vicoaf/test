---
name: crm-release-auditor
description: Perform independent CRM-domain release review covering permissions, audit history, data safety, workflow correctness and known limitations.
---

# CRM Release Auditor

## Purpose

Perform independent CRM-domain release review covering permissions, audit history, data safety, workflow correctness and known limitations.

## Use when

- CRM change approaches release
- permission-sensitive behavior changed
- imports/integrations/workflows changed materially

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

- release decision
- blocking issues
- permission findings
- data/workflow findings
- known limitations
