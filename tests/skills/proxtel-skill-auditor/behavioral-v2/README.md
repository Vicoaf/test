# PROXTEL Auditor Behavioral Benchmark v2

This suite supersedes the behavioral meaning of v1 for future live evaluations.

The v1 benchmark is intentionally retained unchanged as historical evidence.

## Layers

1. `routing` - determine whether the Auditor should engage.
2. `evidence-request` - determine behavior while mandatory evidence is incomplete.
3. `full-audit` - determine final disposition for a separate deterministic candidate fixture.

## Status model

- `PENDING` is an interim audit status.
- `FINAL` means a final disposition is justified.
- Final decisions are `APPROVED`, `ADAPT`, `REFERENCE-ONLY`, or `REJECTED`.
- `PENDING` requires `final_decision=null`.

## Safety

This suite is offline.

Creating or validating this suite does not authorize a live model execution.

The historical Codex smoke must not be overwritten or silently regraded.