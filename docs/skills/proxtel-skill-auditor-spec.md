# proxtel-skill-auditor — Functional Specification

## Status

SPECIFICATION

## Mission

Auditar Skills internas o externas y producir decisiones basadas en evidencia.

El Auditor es independiente del Creator.

## Stage 1 - Identity

Registrar:

- source;
- author;
- repository;
- version;
- commit;
- capture date;
- license;
- file inventory;
- hashes.

## Stage 2 - Integrity

Verificar:

- snapshot hashes;
- missing files;
- unexpected files;
- symlinks;
- submodules;
- binary files.

## Stage 3 - Static Security

Inspeccionar:

- filesystem reads;
- filesystem writes;
- deletes;
- network;
- subprocess;
- shell invocation;
- dynamic execution;
- environment access;
- archive extraction;
- privilege requirements;
- persistence;
- external tools;
- secret access.

Una señal estática no equivale automáticamente a una vulnerabilidad.

## Stage 4 - Dependency Audit

Identificar:

- runtime;
- libraries;
- packages;
- CLIs;
- MCP servers;
- external APIs;
- browser dependencies.

Dependencias implícitas deben marcarse como issue.

## Stage 5 - Semantic Audit

Evaluar:

- purpose clarity;
- triggering;
- non-trigger boundaries;
- specialization;
- progressive disclosure;
- maintainability;
- duplication;
- provider coupling;
- portability;
- quality of examples;
- internal contradictions.

## Stage 6 - Safe-to-Execute Gate

Antes de ejecutar producir:

- PASS;
- WARN;
- FAIL;
- CRITICAL.

Solamente PASS/WARN explícitamente aceptable puede continuar a sandbox.

## Stage 7 - Sandbox Testing

Nunca realizar la primera ejecución en producción.

Utilizar:

- isolated test directory;
- fictitious data;
- restricted secrets;
- controlled environment;
- explicit filesystem boundaries;
- controlled network policy.

## Stage 8 - Evaluation

Cuando corresponda medir:

- trigger precision;
- trigger recall;
- false positives;
- false negatives;
- assertion pass rate;
- task quality;
- errors;
- runtime;
- actual tokens;
- tool calls.

No utilizar output characters como sustituto silencioso de tokens.

## Stage 9 - Baseline

Comparar cuando sea útil:

without Skill
vs
with candidate Skill

Para una actualización:

old Skill
vs
candidate Skill

## Stage 10 - Holdout

Separar train y holdout cuando se optimicen triggers o prompts.

No mostrar el holdout al optimizador.

No declarar mejora si existe degradación material no explicada en holdout.

## Stage 11 - Independent Review

Para Skills importantes utilizar, cuando sea viable:

- independent grader;
- blind comparison;
- evidence verification;
- human review.

## Stage 12 - Decision

Decisiones permitidas:

APPROVED
ADAPT
REFERENCE-ONLY
REJECTED

Toda decisión debe incluir evidencia y razones.

## Approval invariant

STATIC PASS != APPROVED

SEMANTIC PASS != APPROVED

Una aprobación requiere los gates aplicables al riesgo y comportamiento real de la Skill.

## External skills

Las Skills externas permanecen en quarantine hasta que una decisión explícita cambie su estado.

## Production

Nunca utilizar producción como entorno inicial de evaluación.