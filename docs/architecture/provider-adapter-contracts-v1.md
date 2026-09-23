# PROXTEL Provider Adapter Contracts v1

## Purpose

Separar la logica canonica de PROXTEL de las interfaces particulares de Claude Code, Codex y Antigravity.

## Canonical rule

El Skill Auditor es provider-neutral.

Ningun provider define las reglas canonicas de auditoria.

Cada adapter traduce el mismo contrato conductual a una interfaz CLI especifica.

## Current state

Los tres adapters comienzan como candidate v0.1.0.

execution_status=not-executed

Todavia no se ha ejecutado ningun benchmark contra un modelo desde estos adapters.

## Claude

Observed interface:

- non-interactive: --print;
- structured output: --output-format json;
- schema: --json-schema;
- model selection: --model;
- permission controls available;
- dangerous permission bypass forbidden by PROXTEL.

## Codex

Observed interface:

- non-interactive: codex exec;
- positional prompt and stdin supported;
- structured schema: --output-schema <FILE>;
- JSON event output: --json;
- final message capture: --output-last-message;
- model: --model;
- sandbox: --sandbox;
- working directory: -C/--cd;
- dangerous sandbox/approval bypass forbidden by PROXTEL.

The top-level CLI exposes approval-policy controls, but their exact operational binding for the future benchmark remains subject to dry-run validation.

## Antigravity

Observed interface:

- non-interactive: --print;
- structured output: --output-format json;
- schema: --json-schema;
- schema accepts string or path according to local help;
- model: --model;
- agent: --agent;
- mode: --mode;
- sandbox: --sandbox;
- dangerous permission bypass forbidden by PROXTEL.

## Safety

No adapter may silently activate dangerous bypass flags.

Production-first tests are forbidden.

Passing adapter validation does not approve the Skill Auditor.

Adapter contract PASS != Behavioral PASS.

Behavioral PASS != APPROVED.