---
name: crm-workflow-designer
description: Design CRM states, assignments, activities, tasks, SLAs and automation triggers with observable failure handling.
---

# CRM Workflow Designer

## Purpose

Design CRM states, assignments, activities, tasks, SLAs and automation triggers with observable failure handling.

## Use when

- pipeline or task workflows change
- automation is requested
- ownership/assignment behavior must be defined

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

- state model
- transition rules
- automation rules
- idempotency notes
- failure-handling rules
