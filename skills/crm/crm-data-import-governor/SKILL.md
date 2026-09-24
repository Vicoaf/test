---
name: crm-data-import-governor
description: Define safe CRM import mappings, duplicate rules, validation, dry-run expectations and PII handling without mutating production data.
---

# CRM Data Import Governor

## Purpose

Define safe CRM import mappings, duplicate rules, validation, dry-run expectations and PII handling without mutating production data.

## Use when

- CSV/XLS import is requested
- deduplication rules are needed
- migration/import safety must be reviewed

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

- field mapping
- validation rules
- duplicate policy
- reject/error policy
- dry-run acceptance criteria
