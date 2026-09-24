---
name: customer-communication-governor
description: Define customer-facing response standards, templates, channel behavior and sensitive-data boundaries.
---

# Customer Communication Governor

## Purpose

Define customer-facing response standards, templates, channel behavior and sensitive-data boundaries.

## Method

1. Gather evidence before recommendations.
2. Separate verified facts from assumptions and open decisions.
3. Define the smallest service-domain contract needed.
4. Protect authorization, privacy, auditability and customer clarity.
5. Coordinate CRM-domain changes with CRM.
6. Delegate repository implementation to Development.
7. Return deterministic acceptance criteria and limitations.

## Safety

- Read-only discovery first.
- No production/database mutation by default.
- No secret exposure.
- No automatic dependency installation or Git operations.

## Outputs

- communication standard
- template rules
- channel rules
- sensitive-data boundaries
