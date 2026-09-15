# proxtel-skill-creator — Functional Specification

## Status

SPECIFICATION

## Mission

Diseñar y construir Skills PROXTEL reutilizables, mantenibles y provider-neutral.

No certifica su propio resultado.

## Phase 1 - Intake

Capturar:

- objetivo;
- usuarios;
- ejemplos concretos;
- situaciones de uso;
- situaciones donde NO debe activarse;
- providers objetivo;
- herramientas necesarias;
- restricciones;
- riesgos;
- portability requirements.

## Phase 2 - Mechanism Router

Antes de crear una Skill determinar si la capacidad pertenece realmente a:

- Standard / Rule;
- Workflow;
- Agent;
- Subagent;
- Tool;
- MCP;
- Adapter;
- Hook;
- Plugin;
- project-specific configuration;
- Skill.

Si Skill no es el mecanismo correcto, detener creación y recomendar el mecanismo correspondiente.

## Phase 3 - Scope

Clasificar alcance:

- CORE;
- area global;
- reusable project capability;
- workspace/project only;
- provider adapter;
- customer-specific.

## Phase 4 - Design

Definir:

- technical id;
- visible title;
- description;
- triggers;
- non-triggers;
- responsibilities;
- limits;
- workflow;
- resources;
- dependencies;
- completion criteria.

## Phase 5 - Progressive Disclosure

Mantener SKILL.md enfocado.

Mover detalle extenso a `references/` solamente cuando sea útil.

Crear `scripts/` solamente cuando exista una operación determinista o reutilizable que justifique código.

Crear `assets/` solamente cuando la Skill realmente necesite recursos de salida.

## Phase 6 - Scripts

Todo script nuevo debe documentar:

- runtime;
- minimum version;
- dependencies;
- filesystem behavior;
- network behavior;
- subprocess behavior;
- environment variables;
- outputs;
- rollback or cleanup behavior.

No instalar dependencias automáticamente.

## Phase 7 - Candidate

La salida inicial se considera:

CANDIDATE

Nunca:

APPROVED

## Phase 8 - Test Preparation

Preparar cuando corresponda:

- positive trigger cases;
- negative trigger cases;
- boundary cases;
- task assertions;
- expected outputs;
- baseline procedure.

## Phase 9 - Auditor Handoff

Entregar al `proxtel-skill-auditor`:

- candidate path;
- provenance;
- design intent;
- tests;
- dependencies;
- known risks;
- provider compatibility.

## Provider metadata

Metadata exclusiva de Claude, Codex, Antigravity u otros proveedores se genera mediante adapters.

No acoplar el SKILL.md canónico a un proveedor salvo que la Skill sea explícitamente provider-specific.

## Prohibited behavior

El Creator no puede:

- aprobar su propia Skill;
- ocultar dependencias;
- incorporar secretos;
- ejecutar código externo no auditado;
- reemplazar una Skill existente sin revisión;
- asumir que una herramienta está instalada;
- modificar producción para probar una Skill.