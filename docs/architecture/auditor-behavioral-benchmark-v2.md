# Auditor Behavioral Benchmark v2

## Problem

The first live Codex smoke exposed three design defects:

1. `PENDING` was permitted by the response contract but not defined as an interim status by the methodology.
2. A routing-style case was graded as if it were a complete audit.
3. The live prompt embedded the Auditor itself and unintentionally turned the routing case into a partial audit of the Auditor.

## Corrected model

Audit progress and final disposition are separate concepts.

```text
AUDIT STATUS
├── PENDING
└── FINAL
    ├── APPROVED
    ├── ADAPT
    ├── REFERENCE-ONLY
    └── REJECTED
```

## Benchmark layers

### Routing

Tests only whether the Auditor engages and routes correctly.

It does not grade a final decision.

### Evidence request

Uses a distinct synthetic candidate with deliberately incomplete evidence.

Expected state: `PENDING`, with no final decision.

### Full audit

Uses the same distinct synthetic candidate with a complete deterministic evidence package.

Only this layer grades a final decision.

## Historical evidence

Behavioral v1 and the first Codex live smoke remain immutable historical evidence.

They are not silently rewritten to make the prior model response pass.

## Live execution policy

Behavioral v2 validation is offline.

No second live model call is authorized by this repair.