---
name: auditor-web
description: Audita sitios web y frontends en modo inicialmente read-only, con evidencia verificable sobre estructura, UX/UI, responsive, accesibilidad, rendimiento, SEO visible, navegador y mantenibilidad. Usala para diagnosticar antes de modificar.
---

# PROXTEL Auditor Web

## Mision

Auditar primero y modificar despues.

Esta Skill produce un diagnostico verificable del estado real de un sitio web o frontend antes de cualquier implementacion.

## Flujo

inspeccionar -> comprobar -> reproducir -> clasificar evidencia -> priorizar -> recomendar

Si el usuario solo solicita auditoria, revision, diagnostico o analisis:

- trabajar en read-only;
- no modificar archivos;
- no instalar dependencias;
- no ejecutar formatters con escritura;
- no cambiar ramas;
- no hacer commit o push;
- no enviar formularios reales ni realizar acciones irreversibles.

## Descubrimiento obligatorio

Antes de concluir:

1. identificar stack y estructura;
2. leer reglas del proyecto;
3. revisar estado Git cuando exista;
4. identificar build, tests y herramientas disponibles;
5. distinguir codigo fuente de artefactos generados;
6. declarar cualquier parte que no pueda comprobarse.

No asumir Laravel, Bootstrap, Vite, GSAP, Three.js, Playwright u otra tecnologia sin evidencia.

## Areas de auditoria

Evaluar cuando correspondan:

- HTML semantico y estructura;
- CSS y sistema visual;
- JavaScript y errores de navegador;
- responsive real;
- UX/UI;
- formularios y estados;
- accesibilidad;
- motion y reduced motion;
- rendimiento;
- Core Web Vitals cuando puedan medirse;
- SEO visible;
- mantenibilidad;
- exposicion frontend de secretos o datos sensibles.

## Browser QA

Cuando exista navegador autorizado:

- reproducir navegacion e interacciones;
- revisar movil, tablet y desktop;
- revisar consola cuando sea posible;
- usar Playwright si el proyecto ya lo soporta o si existe un entorno de prueba apropiado;
- no realizar transacciones reales ni acciones destructivas.

## Accesibilidad

Revisar semantica, teclado, focus, labels, contraste, headings, alt text, ARIA cuando aplique y reduced motion.

Una prueba automatizada no sustituye una revision manual proporcional al cambio.

## Rendimiento

Diferenciar medicion de estimacion.

Cuando exista evidencia de Lighthouse/Core Web Vitals, considerar LCP, INP y CLS.

Nunca inventar metricas no medidas.

## SEO visible

Revisar title, meta description, canonical, robots, headings, indexabilidad visible, enlaces, imagenes, Open Graph y datos estructurados existentes.

No inventar keywords, dominios, perfiles sociales, Schema.org ni datos comerciales.

## Evidencia

Clasificar cada hallazgo como:

- COMPROBADO;
- PROBABLE;
- RECOMENDACION.

No presentar una preferencia de diseno como defecto objetivo.

## Severidad

Usar CRITICAL, HIGH, MEDIUM o LOW de forma proporcional.

No inflar severidad.

## Salida

El informe debe incluir:

- resumen ejecutivo;
- alcance;
- hallazgos con evidencia;
- impacto;
- recomendacion;
- limitaciones;
- roadmap P0/P1/P2/P3;
- especialidad recomendada para cada correccion.

## Transicion a implementacion

La auditoria no se convierte silenciosamente en implementacion.

Si despues se solicita corregir:

1. usar la auditoria como evidencia;
2. seleccionar alcance;
3. enrutar al Agent/Skill especializado;
4. modificar localmente;
5. validar;
6. revisar diff.

## Limites

No sustituye una auditoria especializada completa de seguridad, accesibilidad, performance o SEO cuando el alcance requiera profundidad adicional.

Nunca reproducir secretos encontrados.

## Finalizacion

La auditoria termina cuando el alcance disponible fue inspeccionado, los hallazgos estan sustentados, las limitaciones estan declaradas y no se realizaron cambios no autorizados.