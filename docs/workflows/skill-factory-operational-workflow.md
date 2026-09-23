# Skill Factory Operational Workflow

## Purpose

This is the first canonical PROXTEL Workflow contract and the operational state machine for Skill Factory.

It was created only after Area 1.4 M1 proved that no prior workflow schema, core workflow, workflow documentation or workflow tests existed.

## Mechanism boundary

Workflow is used because this is a coordinated multi-step process with governance transitions.

It is not implemented as a single Skill because the process coordinates Creator, Auditor, tests, evidence, provider routing and final state transitions.

## Canonical components

- schema: config/schemas/proxtel-workflow.schema.json
- runtime contract: workflows/core/skill-factory/workflow.json
- operating manual: workflows/core/skill-factory/WORKFLOW.md
- deterministic cases: tests/workflows/skill-factory/workflow-cases.json
- test runner: tests/workflows/skill-factory/run-workflow-tests.ps1

## Skill Factory pair

- proxtel-skill-creator: approved
- proxtel-skill-auditor: approved

Creator cannot self-certify.

The Auditor owns the independent final Skill decision.

## Provider pattern

Provider routing is a preference layer, not a governance layer.

Typical pattern:

Claude -> design/architecture
Codex -> implementation/tests
Antigravity -> independent audit/verification

Other valid provider assignments are allowed when the same PROXTEL controls are preserved.

## Safety

The workflow forbids direct execution of unreviewed external sources, production-first tests, silent dependency installation, dangerous permission bypass, secrets in artifacts and automatic retry of consumed live calls.

## Transaction model

staging -> validation -> promote

Rollback is required on failure when technically reversible.

Evidence from consumed live attempts is preserved rather than overwritten.