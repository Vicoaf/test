# PROXTEL Skill Factory Architecture

## Status

PROPOSED

## Context

PROXTEL AI Agency necesita crear, adaptar, auditar, probar y mantener Agent Skills de forma profesional, reproducible y neutral respecto del proveedor.

Se estudiaron tres referencias iniciales:

- PROXTEL `creador-skills` existente.
- Anthropic `skill-creator`.
- OpenAI legacy `skill-creator`.

Las referencias externas permanecen en quarantine y no se consideran Skills aprobadas.

## Decision

Skill Factory se divide en dos responsabilidades independientes:

- `proxtel-skill-creator`
- `proxtel-skill-auditor`

La Skill que crea o modifica una Skill no puede certificar por sí sola su aprobación final.

## Principle

Creator != Auditor

La separación permite revisión independiente y reduce errores correlacionados.

## Provider neutrality

El conocimiento central de Skill Factory no pertenece a Claude, Codex ni Antigravity.

Las diferencias de cada proveedor pertenecen a adapters.

Flujo:

Skill Factory CORE
-> provider adapter
-> Claude / Codex / Antigravity / future provider

## External sources

Las fuentes externas siguen:

SOURCE
-> QUARANTINE
-> STATIC AUDIT
-> SAFE-TO-EXECUTE DECISION
-> SANDBOX TEST
-> EVALUATION
-> FINAL DECISION

## Final decisions

Una Skill auditada puede recibir:

- APPROVED
- ADAPT
- REFERENCE-ONLY
- REJECTED

`STATIC PASS` no equivale a `APPROVED`.

## Safety

Ningún script externo se ejecuta únicamente porque forme parte de una Skill.

Antes de ejecución deben revisarse:

- provenance;
- integrity;
- license;
- dependencies;
- filesystem access;
- subprocess;
- environment access;
- network access;
- destructive behavior;
- external tools;
- secret handling;
- portability.

## Evaluation

Cuando sea materialmente útil se debe comparar:

baseline
vs
candidate Skill

La evaluación puede incluir:

- assertions;
- trigger precision;
- trigger recall;
- false positives;
- false negatives;
- task quality;
- errors;
- runtime;
- actual token usage cuando esté disponible;
- tool calls;
- human feedback.

No etiquetar caracteres como tokens.

## Holdout

Las optimizaciones pueden utilizar train/test split.

El conjunto holdout no debe ser mostrado al optimizador durante la iteración.

El proceso no debe declarar éxito únicamente porque training llegue a 100% si el holdout demuestra degradación importante.

## Viewer

Los reportes deben preferir generación estática y offline.

Un viewer local:

- debe bindear solamente localhost;
- no debe terminar procesos que ocupen otro puerto;
- debe elegir un puerto libre;
- no debe exponer archivos sensibles indiscriminadamente;
- debe limitar el tamaño de archivos y requests.

## Packaging

Antes de empaquetar una Skill:

- validar estructura;
- validar registry;
- detectar secretos;
- rechazar symlinks inesperados;
- excluir caches y artifacts;
- crear hashes;
- conservar provenance/licensing cuando corresponda.

## Transactionality

Los generadores deben trabajar:

staging
-> validation
-> promote

Si existe un fallo antes de promote:

rollback staging

No dejar directorios parcialmente inicializados como resultado válido.

## Dependencies

Toda dependencia externa debe estar declarada.

Nunca instalar dependencias silenciosamente.

## Source references

Anthropic y OpenAI son referencias upstream.

PROXTEL reimplementará los conceptos seleccionados bajo su propia arquitectura, manteniendo trazabilidad de las fuentes utilizadas.