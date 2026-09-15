# PROXTEL AI Agency — Modelo de Agents y Subagents

## Agent

Un Agent es una unidad de responsabilidad profesional.

Un Agent debe tener:

- misión;
- alcance;
- responsabilidades;
- límites;
- Skills disponibles;
- Tools permitidas;
- Workflows compatibles;
- criterios de validación.

Un Agent no debe intentar representar toda la Agencia.

## Ejemplos

- Arquitecto de Software;
- Desarrollador Laravel;
- Auditor Web;
- DBA;
- QA;
- Documentador;
- Auditor de Seguridad;
- Estratega Comercial.

## Agent principal

El Agent principal conserva:

- objetivo global;
- contexto de la tarea;
- alcance autorizado;
- decisiones de coordinación;
- consolidación de resultados.

Puede delegar tareas específicas.

## Subagent

Un Subagent es un especialista temporal o acotado utilizado por otro Agent.

Debe recibir:

- una tarea concreta;
- contexto mínimo suficiente;
- límites claros;
- formato de salida;
- criterio de finalización.

## Cuándo usar Subagents

Usarlos cuando:

- existen especialidades independientes;
- pueden realizarse análisis paralelos;
- se necesita una revisión independiente;
- el contexto principal se beneficiaría de división;
- una tarea tiene fronteras claramente identificables.

## Cuándo no usar Subagents

No utilizarlos solamente para aparentar una arquitectura compleja.

Evitar Subagents cuando:

- la tarea es trivial;
- el coste de coordinación supera el beneficio;
- existe dependencia secuencial fuerte;
- un solo Agent puede completar la tarea con claridad.

## Ejemplo de auditoría

Auditor principal

-> Subagent Laravel
-> Subagent MySQL
-> Subagent Frontend
-> Subagent Seguridad
-> Subagent QA

El Agent principal consolida resultados y elimina duplicados o contradicciones.

## Autoridad

Un Subagent nunca recibe automáticamente más autoridad que el Agent que lo invoca.

Si el Agent principal está en READ ONLY:

los Subagents también están en READ ONLY.

Si una acción requiere aprobación:

el Subagent no puede evitar esa aprobación.

## Estado

Los Subagents deben considerarse preferentemente efímeros.

No es necesario crear un Agent permanente para cada tarea pequeña.

## Resultado

El resultado del trabajo de Subagents debe volver al Agent principal con evidencia suficiente para poder ser revisado.

## Validación independiente

Cuando el riesgo lo justifique, un Agent de QA o auditoría no debe limitarse a repetir la conclusión del Agent implementador.

Debe realizar comprobaciones independientes.

## Responsabilidad

El Agent que consolida la tarea sigue siendo responsable de:

- detectar contradicciones;
- identificar falta de evidencia;
- solicitar o ejecutar validaciones;
- reportar limitaciones.