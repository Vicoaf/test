# PROXTEL Development Software Delivery Workflow

## Status

APPROVED v1.0.0

## Flow

1. Intake and scope.
2. Read-only project discovery.
3. Risk and change classification.
4. Design and plan.
5. Local implementation.
6. Deterministic validation.
7. Web-quality validation when applicable.
8. Independent review when needed.
9. Documentation and handoff.
10. Release-readiness gate.

## Final decisions

- READY
- CHANGES-REQUIRED
- BLOCKED
- DEFERRED

READY does not mean automatic deployment.

Deployment, Git commit and Git push remain separate explicitly authorized actions.

## Web quality

For user-facing web changes validate responsive/browser behavior, accessibility, visual regressions and performance when applicable.

## Provider pattern

Claude -> architecture/reasoning
Codex -> implementation/tests
Antigravity -> research/browser/visual/independent verification

Fallback is allowed only if PROXTEL controls are preserved.