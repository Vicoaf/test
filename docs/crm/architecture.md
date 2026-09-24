# PROXTEL CRM Area Architecture

The CRM area is a domain layer above Development Gold Master.

## Owns

- CRM requirements and lifecycle semantics.
- CRM data/import governance.
- CRM workflow and automation semantics.
- CRM integration contracts.
- CRM-domain release audit.

## Reuses

- Development orchestrator for code implementation.
- Development Tools.
- Development MCP profile.
- Existing CRM project template.
- Approved Development Skills where applicable.

## Does not duplicate

Backend, frontend, database, browser QA, security implementation or build capabilities are not recreated inside CRM.

## Lifecycle

CRM domain artifacts are materialized as candidates. Materialization and testing do not imply certification or activation.
