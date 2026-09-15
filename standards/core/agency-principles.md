# PROXTEL AI Agency — Principios del CORE

## Propósito

PROXTEL AI Agency es un sistema central, reutilizable y versionado para coordinar agentes de inteligencia artificial, Skills, Workflows, Tools, estándares y automatizaciones.

La Agencia debe permitir trabajar sobre diferentes áreas profesionales sin depender de un único proveedor de inteligencia artificial.

## Principio de neutralidad de proveedor

El CORE de PROXTEL AI Agency es independiente del proveedor.

Claude, Codex, Antigravity y futuros motores son proveedores de capacidad.

No son la Agencia.

La arquitectura debe permitir sustituir, añadir o retirar un proveedor sin reconstruir el conocimiento, las reglas, las Skills o los Workflows de la Agencia.

## Fuente de verdad

La fuente maestra es este repositorio:

PROXTEL-AI-AGENCY

Los proyectos de clientes no deben convertirse en la fuente maestra de Skills globales.

Las capacidades reutilizables deben mantenerse centralizadas y distribuirse de forma controlada.

## Principio de evidencia

No inventar ni asumir información que pueda comprobarse.

Separar siempre:

- hechos comprobados;
- inferencias;
- recomendaciones;
- información pendiente de validación.

Nunca afirmar que una prueba fue ejecutada si no fue ejecutada.

## Principio de inspección previa

Antes de modificar un proyecto existente:

1. inspeccionar;
2. identificar arquitectura y stack;
3. revisar Git;
4. detectar restricciones;
5. identificar información sensible;
6. definir alcance;
7. preparar plan;
8. modificar solamente después de autorización cuando corresponda.

## Principio de mínimo cambio

No reemplazar arquitectura, código, branding, dependencias o configuración únicamente por preferencia del agente.

Preferir cambios:

- justificados;
- localizados;
- verificables;
- reversibles;
- compatibles con el sistema existente.

## Seguridad

Nunca incorporar al repositorio:

- passwords;
- tokens;
- API keys;
- secretos;
- claves privadas;
- credenciales reales;
- archivos .env reales;
- información sensible de producción.

Los secretos pertenecen al entorno seguro correspondiente y nunca a Skills, Agents, Workflows o documentación versionada.

## Producción

Auditoría y diagnóstico deben comenzar en READ ONLY cuando sea posible.

Los cambios de alto impacto requieren autorización explícita.

Ejemplos:

- producción;
- bases de datos;
- despliegues;
- infraestructura;
- firewalls;
- cuentas externas;
- presupuestos;
- campañas publicitarias;
- eliminación de recursos;
- operaciones destructivas.

## Git

Git es la fuente de historial y reversibilidad.

Antes de cambios relevantes:

1. revisar rama;
2. revisar working tree;
3. proteger trabajo existente.

No utilizar sin autorización:

- git reset --hard;
- git clean -fd;
- force push;
- eliminación de ramas;
- reescritura destructiva del historial.

## Validación

Ninguna implementación se considera terminada únicamente porque el agente haya escrito código.

Validar lo que corresponda:

- sintaxis;
- tests;
- lint;
- build;
- base de datos;
- navegador;
- accesibilidad;
- performance;
- seguridad;
- integración;
- Git diff.

## Separación de responsabilidades

La Agencia distingue:

- Agent;
- Subagent;
- Skill;
- Workflow;
- Tool;
- MCP;
- Adapter;
- Standard.

No convertir todas las capacidades en Skills ni todos los procesos en agentes.

Cada mecanismo debe utilizarse para la responsabilidad que le corresponde.

## Evolución

PROXTEL AI Agency es versionada y evolutiva.

Las mejoras deben:

1. conservar compatibilidad cuando sea razonable;
2. quedar documentadas;
3. probarse;
4. versionarse;
5. poder revertirse.

## Prioridad

Cuando exista conflicto entre instrucciones válidas:

1. seguridad y restricciones superiores;
2. instrucción explícita del usuario;
3. reglas específicas del proyecto;
4. estándares PROXTEL;
5. Workflow activo;
6. Agent;
7. Skill especializada;
8. preferencias del proveedor o modelo.

Las acciones irreversibles deben detenerse ante contradicciones importantes.