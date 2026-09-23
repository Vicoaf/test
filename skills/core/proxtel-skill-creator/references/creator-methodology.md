# PROXTEL Skill Creator - Methodology

## Purpose

Este documento detalla como convertir una necesidad en un candidate auditable sin confundir Skill con otros mecanismos.

## 1. Intake record

Registrar objetivo, usuarios, ejemplos, triggers, non-triggers, restricciones, providers, herramientas, riesgos, portability y evidencia disponible.

## 2. Mechanism decision

Comparar la necesidad contra Standard/Rule, Workflow, Agent, Subagent, Tool, MCP, Adapter, Hook, Plugin, project configuration y Skill.

La decision debe explicar por que el mecanismo elegido es suficiente y evitar duplicacion.

## 3. Scope decision

Elegir el menor alcance que satisfaga la necesidad: core, area, reusable-project, workspace, provider-adapter o customer-specific.

## 4. Candidate design

Definir id tecnico, display name, summary, use_when, do_not_use_when, responsibilities, limits, completion criteria y dependencias.

## 5. Resource design

SKILL.md contiene el procedimiento operativo principal.

references/ contiene detalle que no necesita cargarse siempre.

scripts/ requiere justificacion de determinismo, runtime, seguridad y rollback.

assets/ se crea solo si forma parte de la salida o plantilla reutilizable.

## 6. Dependency discipline

Toda dependencia debe ser visible. Nunca instalar silenciosamente. Nunca asumir disponibilidad.

## 7. Security declaration

Declarar network, filesystem writes, deletes, subprocess, environment, secrets y privileges de acuerdo con el contrato PROXTEL.

## 8. Testing preparation

Crear casos positivos, negativos y boundary. Separar casos usados para diseno de holdout cuando el riesgo o la complejidad lo requieran.

## 9. Candidate state

El Creator produce lifecycle.state=candidate.

El Registry puede usar under-audit para representar que ese candidate ya esta entregado al proceso de gobernanza. Los vocabularios son distintos.

## 10. Auditor handoff

El handoff debe permitir al Auditor revisar el candidate sin depender de memoria conversacional.

Debe identificar provenance, design intent, tests, dependencies, known risks, provider compatibility y unknowns.

## 11. Approval boundary

Creator self-approval is forbidden.

STATIC PASS no convierte un candidate en approved.

La promocion a approved pertenece al proceso de auditoria y gobernanza.