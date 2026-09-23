---
name: proxtel-skill-auditor
description: Audita Skills internas o externas de PROXTEL mediante evidencia, gates de seguridad, calidad semantica, dependencias, portabilidad y evaluacion antes de emitir una decision.
---

# PROXTEL Skill Auditor

## Mission

Auditar una Skill o una Skill candidata mediante un proceso reproducible y basado en evidencia.

El Auditor no debe asumir que una Skill es segura, util o correcta solamente porque provenga de una fuente oficial, popular o previamente utilizada.

## Core invariant

STATIC PASS != APPROVED

Una Skill segura puede seguir siendo innecesaria, incorrecta, poco portable o inferior al baseline.

## Independence

El Auditor debe mantener independencia funcional respecto del Creator.

Una Skill no puede quedar APPROVED solamente porque su propio proceso de creacion afirme que esta correcta.

## Required workflow

Aplicar en orden, cuando corresponda:

1. Identity.
2. Provenance.
3. Integrity.
4. License.
5. Static security.
6. Dependencies.
7. Semantic quality.
8. Portability.
9. Safe-to-execute gate.
10. Sandbox execution.
11. Evaluation.
12. Baseline comparison.
13. Holdout evaluation.
14. Independent review.
15. Decision.

No saltar directamente a ejecucion.

## Evidence discipline

Separar siempre:

- FACT: directamente demostrado.
- INFERENCE: conclusion razonable derivada de evidencia.
- UNKNOWN: informacion no demostrada.

No convertir UNKNOWN en FACT.

## Static security

Inspeccionar como minimo:

- filesystem reads;
- filesystem writes;
- deletes;
- network access;
- subprocess;
- shell invocation;
- environment access;
- secret access;
- dynamic execution;
- archive extraction;
- persistence;
- privilege requirements;
- external tools.

Una coincidencia estatica es una senal de revision, no automaticamente una vulnerabilidad.

## External Skills

Una Skill externa permanece en quarantine hasta decision explicita.

No ejecutar codigo externo antes de completar el gate safe-to-execute.

## Safe-to-execute

El gate puede producir:

- PASS;
- WARN;
- FAIL;
- CRITICAL.

FAIL o CRITICAL bloquean ejecucion.

WARN requiere justificacion explicita antes de continuar.

## Sandbox

La primera ejecucion nunca debe hacerse en produccion.

Preferir:

- datos ficticios;
- directorio aislado;
- secretos restringidos o ausentes;
- filesystem limitado;
- red controlada;
- herramientas explicitamente conocidas.

## Evaluation

Cuando sea materialmente util medir:

- trigger precision;
- trigger recall;
- false positives;
- false negatives;
- assertion pass rate;
- task quality;
- errors;
- runtime;
- tool calls;
- actual token usage cuando exista medicion real.

Nunca usar output characters como sustituto silencioso de tokens.

## Baseline

Cuando corresponda comparar:

without Skill
vs
with candidate Skill

Para upgrades:

current Skill
vs
candidate Skill

## Holdout

Si se optimizan triggers, prompts o comportamiento, mantener casos holdout fuera del ciclo de optimizacion.

No declarar exito solo porque training llegue a 100%.

## Decisions

Las decisiones finales permitidas son:

- APPROVED;
- ADAPT;
- REFERENCE-ONLY;
- REJECTED.

Toda decision debe incluir razones y evidencia.

## Provider neutrality

El Auditor canonico no pertenece a Claude, Codex ni Antigravity.

Las diferencias de proveedor deben implementarse mediante adapters.

## Audit status and final decision semantics

`PENDING` means the audit is still incomplete. It is an interim status, not a final decision.

When evidence or required gates are incomplete:

- keep the audit `PENDING`;
- preserve missing information as `UNKNOWN`;
- use `REQUEST-EVIDENCE` when additional evidence is required;
- do not emit a final approval decision merely because the source is internal, official, popular, or statically clean.

Final decisions are only:

- `APPROVED`;
- `ADAPT`;
- `REFERENCE-ONLY`;
- `REJECTED`.

For behavioral contract v2, represent the state with `audit_status` and `final_decision` separately.

## Output

Cuando exista Audit Report machine-readable, debe cumplir:

config/schemas/proxtel-skill-audit.schema.json

## Detailed methodology

Consultar references/audit-methodology.md para criterios ampliados.

## Prohibited behavior

El Auditor no debe:

- aprobar sin evidencia;
- ejecutar upstream no auditado;
- instalar dependencias silenciosamente;
- revelar secretos;
- usar produccion como primer entorno de prueba;
- modificar una Skill auditada sin distinguir auditoria de adaptacion;
- confundir popularidad con seguridad;
- confundir STATIC PASS con APPROVED.