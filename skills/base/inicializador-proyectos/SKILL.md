---
name: inicializador-proyectos
description: Analiza, planifica e inicializa proyectos profesionales de desarrollo web, Laravel, CRM, dashboards y SaaS, creando una base técnica coherente con el stack, branding, Git, documentación, testing y configuración agentic. Úsala al comenzar un proyecto nuevo, preparar un entorno, definir estructura inicial, configurar branding, crear la base de un repositorio o estandarizar un proyecto antes del desarrollo. Interactúa en español.
---

# Inicializador Profesional de Proyectos

## Objetivo

Preparar correctamente un proyecto antes de comenzar el desarrollo.

La función de esta Skill es establecer una base:

- técnica;
- visual;
- organizativa;
- versionable;
- documentada;
- mantenible;
- preparada para agentes de IA;
- preparada para testing;
- preparada para crecimiento.

No comenzar construyendo funcionalidades complejas antes de definir correctamente el proyecto.

---

# Principio fundamental

Primero comprender.

Después decidir.

Finalmente inicializar.

El flujo general es:

requerimientos
→ clasificación del proyecto
→ stack
→ arquitectura
→ branding
→ repositorio
→ documentación
→ configuración agentic
→ estructura
→ validación

---

# No asumir el tipo de proyecto

Antes de inicializar, determinar si se trata de:

- landing page;
- sitio corporativo;
- sitio multipágina;
- aplicación PHP;
- aplicación Laravel;
- CRM;
- dashboard;
- portal;
- API;
- SaaS;
- frontend para backend existente;
- proyecto legacy;
- otro tipo.

No aplicar la misma estructura a todos los proyectos.

---

# Información inicial

Cuando sea relevante, identificar:

- nombre del proyecto;
- objetivo;
- cliente;
- audiencia;
- tipo de aplicación;
- alcance inicial;
- funcionalidades principales;
- stack solicitado;
- stack existente;
- requisitos de branding;
- idiomas;
- integraciones;
- entorno local;
- entorno de producción previsto;
- requerimientos de seguridad;
- necesidades de testing;
- repositorio existente.

Si un dato no es imprescindible para comenzar, no bloquear innecesariamente el proceso.

Cuando falte información no crítica:

- utilizar una estructura conservadora;
- documentar la decisión;
- evitar inventar requisitos comerciales.

---

# Proyecto existente vs proyecto nuevo

## Proyecto nuevo

Puede inicializar:

- estructura;
- Git;
- documentación;
- configuración agentic;
- tooling;
- branding base;
- dependencias necesarias;
- testing inicial.

## Proyecto existente

No reinicializar automáticamente.

Primero:

1. inspeccionar;
2. identificar stack;
3. revisar Git;
4. detectar estructura;
5. identificar configuraciones existentes;
6. detectar documentación;
7. identificar herramientas instaladas.

Después proponer únicamente los elementos faltantes.

Nunca reemplazar una configuración válida simplemente para ajustarla a una plantilla.

---

# Clasificación del stack

Antes de crear archivos detectar o definir el stack.

Ejemplos:

## Sitio web estático

Puede utilizar:

- HTML5;
- CSS;
- JavaScript;
- Bootstrap;
- Vite cuando esté justificado.

## Laravel

Puede utilizar:

- PHP;
- Laravel;
- Blade;
- Bootstrap;
- JavaScript;
- Vite;
- MySQL/MariaDB;
- testing Laravel.

## CRM / SaaS

Puede requerir:

- Laravel;
- MySQL/MariaDB;
- Blade/Livewire/Inertia según proyecto;
- queues;
- scheduler;
- APIs;
- almacenamiento;
- roles/permisos;
- testing;
- documentación técnica.

No añadir componentes que todavía no sean necesarios.

---

# Entorno del sistema operativo

Detectar el entorno antes de generar comandos.

Puede ser:

- Windows PowerShell;
- PowerShell 7;
- CMD;
- Git Bash;
- Linux;
- macOS.

No asumir Bash cuando el usuario trabaja en Windows.

Generar comandos compatibles con el entorno real.

---

# Control de versiones

Git debe considerarse parte fundamental del proyecto salvo que exista una razón explícita para no utilizarlo.

Para un proyecto nuevo:

1. comprobar disponibilidad de Git;
2. inicializar repositorio cuando esté autorizado;
3. establecer `.gitignore`;
4. crear baseline inicial;
5. definir estrategia de ramas cuando corresponda.

No realizar automáticamente:

- push;
- creación de repositorios remotos;
- force push;
- publicación;

sin autorización.

---

# Protección de secretos

Desde el inicio:

- excluir `.env`;
- excluir credenciales;
- excluir claves privadas;
- excluir tokens;
- excluir archivos temporales sensibles.

Cuando el stack utilice variables de entorno:

crear o mantener un archivo de ejemplo cuando corresponda, como:

`.env.example`

sin incluir secretos reales.

---

# Configuración agentic

Los proyectos profesionales deben prepararse para agentes cuando esa metodología esté siendo utilizada.

Considerar:

`AGENTS.md`

para instrucciones del proyecto compatibles con Codex.

Considerar:

`.agents/`

para personalizaciones del workspace.

Estructura posible:

```text
.agents/
├── skills/
└── rules/