# PROXTEL Provider Harness v2

## Status

CANDIDATE

## Objective

Provide a provider-neutral and reproducible bridge between Behavioral Benchmark v2 and provider-specific execution adapters.

## Separation invariant

The harness distinguishes Auditor operating instructions, candidate under audit and benchmark grading data.
These concepts must never be merged.

OPERATING INSTRUCTIONS = proxtel-skill-auditor
CANDIDATE UNDER AUDIT = fixture-safe-summarizer
GRADING DATA = harness-only; never model-facing

The routing layer has no candidate artifact.

## Anti-contamination rule

The harness must not present proxtel-skill-auditor as the candidate, embed expected values, expose grading metadata, reuse the v1 contaminated prompt, or silently regrade the historical v1 smoke.

## Provider plans

Claude, Codex and Antigravity each receive three offline plans, for nine plans total.
The plans are not executions.

## Codex

The resolved safe sandbox requirement is read-only. This does not authorize execution.

## Claude and Antigravity

Exact safe runtime bindings remain deferred until a separate live-preflight stage.
No runtime mode is invented by this harness.

## Future live evaluation

A future live smoke must use Behavioral v2, the v2 response schema, isolated temporary working directory, fresh auth checks, fresh zero-extra-cost checks, no API-key fallback, no automatic retry, and separate explicit user authorization.
Recommended first future case: evidence-incomplete-candidate. This document does not authorize execution.