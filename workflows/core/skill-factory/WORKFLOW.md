# PROXTEL Skill Factory Operational Workflow

## Status

APPROVED v1.0.0

## Mission

Coordinar el ciclo completo de Skills PROXTEL sin mezclar las responsabilidades de Creator y Auditor.

## Core rule

Creator != Auditor.

El Creator crea o adapta candidates.

El Auditor realiza la revision independiente y emite la decision final.

El Workflow coordina estados, evidencia, transiciones, rollback y cierre.

## Operating flow

1. Intake and source classification.
2. Mechanism Router.
3. External quarantine when applicable.
4. Creator builds candidate in staging.
5. Deterministic validation.
6. Auditor static review.
7. Sandbox when executable behavior and risk make it applicable.
8. Evaluation, baseline and holdout when applicable.
9. Independent final decision.
10. Decision transition.
11. Final regression and closure.

## Final decisions

- APPROVED: promotion is allowed only with FINAL audit, promotion_eligible=true and zero blockers.
- ADAPT: return required actions to Creator; create a new candidate before another audit.
- REFERENCE-ONLY: preserve as reference, not as trusted active Skill.
- REJECTED: no promotion.

## External sources

External material always enters quarantine first.

SOURCE -> QUARANTINE -> STATIC AUDIT -> SAFE-TO-EXECUTE -> SANDBOX IF APPLICABLE -> EVALUATION -> FINAL DECISION

No external script is trusted or executed merely because it was downloaded.

## Transactionality

Use staging -> validation -> promote.

A pre-promote failure rolls back staging.

A post-promote failure restores exact backups when technically reversible and preserves audit evidence.

## Live calls

Automatic retry of a consumed live model attempt is forbidden.

A new attempt requires a fresh packet and evidence that the previous failure occurred before model inference or an explicit governance reason for a new review.

## Provider neutrality

The workflow contract is canonical and provider-neutral.

Provider selection follows task type, risk, tools, cost constraints and availability.

Provider-specific CLI mechanics belong in adapters, not in this workflow.

## Cost policy

Prefer capabilities already included in available subscriptions.

Do not silently introduce paid API, infrastructure or service consumption.

## Completion

A Skill Factory cycle is closed only after the final decision transition and applicable post-transition regression are documented.