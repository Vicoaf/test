# PROXTEL AI Agency Development System

Sistema maestro de desarrollo asistido por IA para proyectos web, Laravel, CRM, APIs y SaaS.

## Objetivo

Mantener en un único repositorio:

- Skills reutilizables.
- Reglas globales.
- Templates de proyectos.
- Scripts de instalación y sincronización.
- Estándares técnicos.
- Documentación de la agencia.

## Herramientas principales

### IDE principal

Visual Studio Code

Perfil:

PROXTEL AI Agency

### Inteligencia artificial

- OpenAI Codex
- Google Antigravity
- ChatGPT
- Gemini

### Backend

- PHP
- Laravel
- MySQL

### Frontend

- HTML
- CSS
- JavaScript
- Bootstrap
- Vite

Las tecnologías adicionales como GSAP, Three.js, Livewire, Vue, React o Tailwind se incorporan únicamente cuando el proyecto las justifique.

## Runtime local

Laravel Herd es el runtime principal para PHP y Laravel.

Laragon se conserva principalmente para MySQL y proyectos legacy cuando corresponda.

TablePlus se utiliza para administración visual de bases de datos.

## Estructura

global-rules/
    Copias maestras de reglas globales para Codex y Antigravity.

skills/
    Biblioteca maestra de Agent Skills.

templates/
    Plantillas reutilizables para diferentes tipos de proyectos.

scripts/
    Scripts de instalación, sincronización y validación.

docs/
    Documentación técnica del sistema de desarrollo.

## Skills base

- creador-skills
- auditor-web
- maestro-frontend
- inicializador-proyectos
- estratega-seo

## Política de trabajo

Antes de modificar proyectos existentes:

1. Inspeccionar.
2. Revisar Git.
3. Auditar.
4. Crear un plan.
5. Implementar cambios controlados.
6. Ejecutar pruebas.
7. Revisar diff.
8. Validar en navegador cuando corresponda.

## Producción

Nunca se debe desplegar directamente a producción sin autorización explícita.

El flujo recomendado es:

desarrollo local -> pruebas -> staging -> producción

## Fuente de verdad

Las Skills almacenadas en este repositorio se convertirán en la fuente maestra.

Las ubicaciones globales de Antigravity y otros agentes serán sincronizadas mediante scripts controlados.
