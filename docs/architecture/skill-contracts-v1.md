# PROXTEL Skill Contracts v1

## Purpose

Skill Factory utiliza contratos machine-readable para separar:

- contenido operativo para agentes;
- metadata interna PROXTEL;
- resultados de auditoria;
- estado del Registry.

## Canonical Skill files

Una futura Skill PROXTEL podra contener:

    skill-name/
    |-- SKILL.md
    |-- skill.json
    |-- scripts/
    |-- references/
    -- assets/

No todos los directorios son obligatorios.

SKILL.md contiene las instrucciones operativas.

skill.json contiene metadata interna PROXTEL y debe cumplir:

config/schemas/proxtel-skill.schema.json

## Audit reports

Una auditoria machine-readable debe cumplir:

config/schemas/proxtel-skill-audit.schema.json

Un Audit Report no reemplaza la evidencia detallada; la referencia mediante evidence IDs.

## Lifecycle

Flujo conceptual:

    draft
      |
      v
    candidate
      |
      v
    under-audit
      |
      +--> adapt
      +--> reference-only
      +--> rejected
      |
      v
    approved

deprecated representa una Skill anteriormente utilizable que ya no debe seleccionarse para trabajo nuevo.

## Creator responsibility

Creator puede generar:

- SKILL.md;
- skill.json;
- resources;
- test definitions.

La salida del Creator queda como candidate.

Creator no puede escribir approved como decision final.

## Auditor responsibility

Auditor produce el Audit Report.

STATIC PASS no significa APPROVED.

El Audit Report registra gates independientes.

## Registry responsibility

El Registry mantiene el estado oficial dentro de la Agencia.

El Registry no debe declarar approved si no existe una decision de auditoria compatible.

## Provider adapters

La metadata especifica de proveedor no pertenece al contrato canonico salvo que la Skill sea explicitamente provider-specific.

Ejemplos:

    adapters/claude/
    adapters/codex/
    adapters/antigravity/

## Security declarations

El contrato obliga a declarar comportamiento relacionado con:

- network;
- filesystem writes;
- filesystem deletes;
- subprocess;
- environment;
- secrets;
- privileges.

Una declaracion no reemplaza la auditoria.

## Dependencies

Una dependencia debe indicar al menos:

- type;
- name;
- whether it is required;
- installation policy.

La politica explicit significa que PROXTEL no debe instalarla silenciosamente.

## Tokens

El Audit Report permite token_measurement = actual solamente cuando existe una medicion real.

Si no existe una medicion real debe utilizar:

token_measurement = not-measured

Nunca utilizar output characters como sustituto de tokens.

## Schema version

La version inicial de ambos contratos es 1.0.

Cambios incompatibles futuros requieren una nueva version del contrato.