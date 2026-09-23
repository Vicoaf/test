# PROXTEL Provider Harness v2

## Purpose

Prepare provider-neutral behavioral evaluation inputs for proxtel-skill-auditor v0.2.0 without executing any provider.

## Role separation

The Auditor is the operating procedure.
The Auditor is not the candidate under audit.
For candidate-based cases, the only candidate is fixture-safe-summarizer.

## Behavioral layers

1. routing
2. evidence-request
3. full-audit

## Model-facing data

Model-facing candidate/evidence projections intentionally remove grading metadata.
The following source-fixture fields are never sent to the model:
- synthetic_expected_disposition
- final_decision_supported
- candidate_under_test
- auditor_under_test

## Provider plans

The harness contains offline plans for Claude, Codex and Antigravity.
Each provider has one plan for each behavioral layer.
No plan is authorized for execution.

## Live execution

A future live execution requires separate explicit authorization, fresh authentication checks and a fresh zero-extra-cost check.
The historical v1 smoke is evidence only and must never be silently reused or regraded.