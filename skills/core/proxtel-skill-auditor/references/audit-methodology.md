# PROXTEL Skill Audit Methodology

## 1. Identity

Registrar nombre, ID, ubicacion, version y tipo de Skill.

## 2. Provenance

Para fuentes externas registrar cuando exista:

- repository;
- author;
- commit;
- capture date;
- license;
- provenance metadata.

## 3. Integrity

Verificar hashes, archivos faltantes, archivos inesperados, symlinks, submodules y binarios.

## 4. License

Distinguir licencia presente, ausente, ambigua o incompatible con el uso previsto.

## 5. Static security

Clasificar comportamiento potencial de filesystem, network, subprocess, environment, secrets y privilegios.

## 6. Dependencies

Inventariar runtimes, libraries, CLIs, MCPs, APIs, browser dependencies y servicios.

Toda dependencia implicita debe marcarse.

## 7. Semantic audit

Evaluar:

- claridad de proposito;
- triggers;
- non-triggers;
- alcance;
- duplicacion;
- progressive disclosure;
- contradicciones;
- mantenibilidad;
- provider coupling;
- portability.

## 8. Safe-to-execute gate

PASS: comportamiento entendido y riesgo controlable.

WARN: existen riesgos conocidos que requieren justificacion.

FAIL: existe riesgo no aceptable o falta informacion material.

CRITICAL: posibilidad material de dano grave, exfiltracion, persistencia o ejecucion peligrosa.

## 9. Sandbox

Definir explicitamente limites de filesystem, network, secretos, procesos y datos.

## 10. Evaluation

Usar assertions observables siempre que sea posible.

Las metricas deben distinguir medicion real de ausencia de medicion.

## 11. Baseline

Una Skill debe demostrar valor cuando su costo o riesgo haga necesaria comparacion.

## 12. Holdout

Separar casos usados para optimizacion de casos usados para validacion final.

## 13. Independent review

Para Skills de impacto alto usar una revision separada cuando sea viable.

## 14. Decision


### Audit status vs final decision

`PENDING` is an interim audit status. It is not a final decision.

Use `PENDING` when mandatory evidence or applicable gates remain incomplete and a final disposition cannot yet be justified.

A pending audit must fail closed:

- do not approve;
- do not execute when execution authorization has not been established;
- identify missing evidence as `UNKNOWN`;
- request the evidence or actions required to continue.

The only final audit decisions are:

- `APPROVED`;
- `ADAPT`;
- `REFERENCE-ONLY`;
- `REJECTED`.

Behavioral contract v2 represents these concepts separately:

- `audit_status=PENDING` requires `final_decision=null`;
- `audit_status=FINAL` requires one of the four final decisions;
- `audit_status=NOT-APPLICABLE` requires `final_decision=null`.

Legacy behavioral contract v1 may encode the interim state as `decision=PENDING`. Treat that representation as compatibility-only and never as a final decision.
APPROVED: supera todos los gates aplicables.

ADAPT: contiene valor, pero requiere cambios antes de aprobacion.

REFERENCE-ONLY: util como fuente conceptual, no como Skill operativa.

REJECTED: no debe incorporarse al sistema operativo de Skills.

## Evidence model

Cada hallazgo debe poder relacionarse con evidencia identificable.

Un Audit Report debe poder ser revisado posteriormente sin depender de memoria conversacional.