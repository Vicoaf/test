# PROXTEL Skill Factory Operator

## Purpose

scripts/skill-factory.ps1 is the practical daily entrypoint for the certified Skill Factory.

It does not call Claude, Codex or Antigravity directly in v1.0.0.

It creates and inspects deterministic run packets while keeping provider execution and governed repository mutation as separate later steps.

## Modes

### Status

Read-only readiness check.

Example:

powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\skill-factory.ps1 -Mode Status

### Plan

Read-only operation plan.

Example:

powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\skill-factory.ps1 -Mode Plan -Action Create -Area development -Request "Create a reusable Laravel audit Skill."

### Start

Creates a runtime run packet outside the repository by default.

Example:

powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\skill-factory.ps1 -Mode Start -Action Create -Area development -Request "Create a reusable Laravel audit Skill."

### Show

Displays an existing run packet.

Example:

powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\skill-factory.ps1 -Mode Show -RunId sf-YYYYMMDD-HHMMSS-xxxxxxxx

## Actions

- Create: new internal Skill candidate flow.
- Update: existing Skill update; SubjectId is required.
- AuditExternal: external source; SourcePath is required and is snapshotted into runtime quarantine without execution.

## Default runtime workspace

%LOCALAPPDATA%\PROXTEL-AI-AGENCY\skill-factory\runs

Runtime packets are intentionally outside the Git repository.

## Safety

- repository mutation is not performed by this operator version;
- provider execution is not performed by this operator version;
- automatic retry of consumed live attempts is disabled;
- external material is copied to runtime quarantine and never executed by Start;
- run creation uses temporary staging and promotes only after run.json validation.

## Provider handoff

The run packet records next_stage and next_owner. Provider-specific execution belongs to adapters or later governed operator extensions, not to the canonical v1 entrypoint.

## Governance

The approved Skill Factory Workflow remains the source of truth for lifecycle rules. Creator creates candidates; Auditor independently reviews; final promotion requires the approved governance path.