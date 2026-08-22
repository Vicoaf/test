---
name: creador-skills
description: Diseña, audita, corrige y mejora Agent Skills para Google Antigravity siguiendo el estándar actual de SKILL.md. Úsala cuando el usuario solicite crear una skill, mejorar una skill existente, auditar un SKILL.md, reorganizar una biblioteca de skills o decidir si una capacidad debe implementarse como Skill, Rule, Hook, Plugin, MCP u otra personalización. Interactúa en español.
---

# Creador y Auditor de Agent Skills

## Objetivo

Diseñar y mantener Skills especializadas, claras, reutilizables y seguras para Google Antigravity.

Una Skill debe aportar conocimiento, procedimientos, convenciones o recursos especializados que mejoren la capacidad del agente para realizar un tipo concreto de tarea.

No convertir automáticamente cualquier instrucción en una Skill.

Antes de crear una Skill, determinar si una Skill es realmente el mecanismo adecuado.

---

## Principio fundamental

Una buena Skill debe hacer una cosa bien.

Evitar Skills monolíticas que intenten concentrar:

- frontend
- backend
- seguridad
- SEO
- bases de datos
- deployment
- testing
- documentación

en una sola definición.

Cuando existan responsabilidades claramente independientes, recomendar Skills separadas.

---

## Jerarquía de configuración

Antes de duplicar instrucciones, considerar que pueden existir reglas globales o específicas del proyecto.

No repetir dentro de cada Skill reglas universales que ya estén definidas en:

- `GEMINI.md`
- Rules del workspace
- configuración global de Antigravity
- políticas del proyecto

La Skill debe contener principalmente conocimiento especializado relacionado con su responsabilidad.

---

## Cuándo crear una Skill

Crear o recomendar una Skill cuando exista:

- un procedimiento especializado reutilizable;
- conocimiento de dominio que el agente necesite aplicar repetidamente;
- una metodología concreta de análisis;
- una convención técnica específica;
- un checklist especializado;
- una estrategia de implementación;
- recursos o scripts especializados;
- un proceso que requiera decisiones específicas según el contexto.

Ejemplos:

- auditoría de accesibilidad;
- arquitectura Laravel;
- auditoría SEO;
- diseño de APIs;
- optimización de Core Web Vitals;
- revisión de consultas MySQL;
- creación de interfaces premium;
- pruebas Playwright.

---

## Cuándo NO crear una Skill

No crear una Skill automáticamente cuando la necesidad corresponde mejor a otro mecanismo.

### Regla persistente

Si la instrucción debe cumplirse prácticamente siempre, probablemente corresponde a una Rule o a `GEMINI.md`.

Ejemplos:

- responder en español;
- no mostrar credenciales;
- no modificar `.env`;
- revisar Git antes de cambios importantes.

### Automatización por evento

Si una acción debe ejecutarse automáticamente antes o después de determinadas operaciones, evaluar un Hook.

Ejemplos:

- ejecutar Prettier después de editar;
- ejecutar lint;
- comprobar ciertos archivos antes de commits o builds.

### Integración externa

Si el agente necesita conectarse a una herramienta, aplicación, servicio o API externa, evaluar MCP o un Plugin.

### Configuración específica de un solo proyecto

Si la instrucción únicamente tiene sentido dentro de un repositorio, preferir una Skill del workspace en:

`.agents/skills/`

en lugar de convertirla innecesariamente en una Skill global.

---

## Ubicación recomendada

Antes de crear una Skill determinar su alcance.

### Skill global del IDE

Usar para capacidades generales reutilizables en diferentes proyectos.

Ruta habitual:

`~/.gemini/config/skills/<nombre-skill>/SKILL.md`

### Skill del workspace

Usar para conocimiento específico del proyecto o del equipo.

Ruta:

`.agents/skills/<nombre-skill>/SKILL.md`

Preferir Skills del workspace cuando dependan de:

- arquitectura específica del proyecto;
- convenciones del repositorio;
- despliegue específico;
- reglas comerciales;
- APIs particulares;
- estructura propia del cliente.

---

## Estructura mínima

Cada Skill debe tener su propia carpeta.

Ejemplo:

`.agents/skills/code-review/`

y contener como mínimo:

`SKILL.md`

Puede contener adicionalmente:

- `scripts/`
- `examples/`
- `resources/`

No crear estos directorios si no son necesarios.

---

## Frontmatter

Todo `SKILL.md` debe comenzar con frontmatter YAML válido.

Formato recomendado:

```yaml
---
name: nombre-de-la-skill
description: Descripción clara de qué hace la Skill y cuándo debe utilizarse.
---