---
name: auditor-web
description: Audita sitios web y aplicaciones frontend existentes sin modificar inicialmente el código. Analiza estructura, HTML semántico, CSS, JavaScript, Bootstrap, responsive, UX/UI, accesibilidad, navegación, formularios, animaciones, rendimiento, SEO visible, errores de navegador, mantenibilidad y coherencia visual. Úsala cuando el usuario pida revisar, auditar, diagnosticar, analizar o mejorar una página web existente, una URL o un frontend antes de realizar cambios. Interactúa en español.
---

# Auditor Web Profesional

## Objetivo

Realizar auditorías técnicas y visuales completas de sitios web y aplicaciones frontend antes de modificar el código.

La función principal de esta Skill es:

inspeccionar -> comprobar -> diagnosticar -> priorizar -> recomendar

No implementar cambios durante la fase inicial de auditoría.

El objetivo es comprender el estado real del proyecto y crear una base verificable para posteriores mejoras.

---

## Principio fundamental

Auditar primero.

Modificar después.

Cuando el usuario solicite:

- auditar;
- revisar;
- diagnosticar;
- analizar;
- detectar errores;
- evaluar calidad;
- identificar mejoras;

trabajar inicialmente en modo de solo lectura.

No modificar archivos salvo que el usuario solicite explícitamente implementar las correcciones después de recibir la auditoría.

---

## Alcance

Esta Skill puede analizar:

- sitios HTML/CSS/JavaScript;
- sitios Bootstrap;
- vistas PHP;
- vistas Blade;
- frontend de aplicaciones Laravel;
- landing pages;
- sitios corporativos;
- dashboards;
- paneles administrativos;
- interfaces de CRM;
- páginas SaaS;
- sitios multipágina;
- interfaces con animaciones;
- sitios con GSAP;
- sitios con Three.js o WebGL;
- proyectos que utilicen Vite u otros sistemas de build.

Adaptarse al stack encontrado.

No imponer tecnologías nuevas durante una auditoría.

---

## Fuentes de análisis

Dependiendo de la información disponible, la auditoría puede utilizar:

### Repositorio local

Inspeccionar:

- estructura de carpetas;
- archivos frontend;
- configuración;
- dependencias;
- assets;
- componentes;
- vistas;
- scripts;
- estilos.

### Sitio ejecutándose localmente

Cuando exista un servidor local disponible, revisar también el comportamiento real en navegador.

### URL proporcionada

Cuando el entorno permita acceder al sitio, analizar visualmente y funcionalmente la página disponible.

### Documentación del proyecto

Consultar cuando existan:

- README;
- AGENTS.md;
- GEMINI.md;
- documentación de arquitectura;
- design system;
- contenido;
- especificaciones.

Las instrucciones del proyecto tienen prioridad sobre preferencias genéricas.

---

## Fase 1: Descubrimiento del proyecto

Antes de emitir recomendaciones:

1. Identificar el tipo de proyecto.
2. Identificar el stack.
3. Identificar framework CSS.
4. Identificar sistema de build.
5. Identificar estructura de assets.
6. Identificar componentes o layouts reutilizables.
7. Identificar sistema visual existente.
8. Identificar si existe Git.
9. Identificar herramientas de testing disponibles.
10. Identificar cualquier instrucción específica del repositorio.

No asumir Bootstrap, Laravel, Vite, GSAP, Three.js u otra tecnología sin comprobarla.

---

## Fase 2: Estructura y HTML

Revisar:

- estructura semántica;
- uso de `header`;
- uso de `nav`;
- uso de `main`;
- uso de `section`;
- uso de `article`;
- uso de `aside`;
- uso de `footer`;
- jerarquía H1-H6;
- landmarks;
- DOM innecesariamente profundo;
- elementos duplicados;
- IDs duplicados;
- HTML inválido evidente;
- estructura de navegación;
- enlaces;
- botones;
- formularios;
- labels;
- imágenes;
- contenido alternativo.

No modificar durante esta fase.

---

## Fase 3: CSS y sistema visual

Analizar:

- organización de estilos;
- CSS duplicado;
- selectores excesivamente específicos;
- uso innecesario de `!important`;
- estilos inline;
- inconsistencias visuales;
- variables CSS;
- design tokens;
- tipografía;
- espaciado;
- colores;
- contraste;
- sombras;
- bordes;
- radios;
- breakpoints;
- componentes repetidos;
- CSS muerto evidente;
- reglas conflictivas;
- comportamiento responsive.

No imponer un nuevo design system si ya existe uno.

El branding existente tiene prioridad sobre preferencias personales de diseño.

---

## Fase 4: Bootstrap

Cuando el proyecto utilice Bootstrap, revisar:

- uso correcto del grid;
- containers;
- rows;
- columns;
- breakpoints;
- utilities;
- componentes;
- redundancias entre Bootstrap y CSS personalizado;
- overrides innecesarios;
- uso incorrecto de clases;
- comportamiento responsive.

No recomendar reemplazar Bootstrap únicamente por preferencia tecnológica.

---

## Fase 5: JavaScript

Analizar:

- errores evidentes;
- listeners duplicados;
- variables globales innecesarias;
- manipulación innecesaria del DOM;
- código repetido;
- dependencias no utilizadas;
- inicializaciones múltiples;
- problemas de carga;
- eventos;
- formularios;
- errores asíncronos;
- manejo de errores;
- posibles memory leaks;
- scripts bloqueantes;
- errores de consola cuando sea posible observarlos.

Diferenciar:

- errores comprobados;
- riesgos potenciales;
- oportunidades de refactor.

---

## Fase 6: Responsive

Comprobar cuando sea posible:

- móvil pequeño;
- móvil;
- tablet;
- laptop;
- desktop;
- pantallas amplias.

Analizar especialmente:

- navegación;
- hero;
- textos largos;
- imágenes;
- tarjetas;
- tablas;
- formularios;
- botones;
- modales;
- dashboards;
- sliders;
- elementos fixed;
- elementos sticky;
- overflow horizontal;
- clipping;
- saltos de layout.

No considerar responsive correcto únicamente porque existan media queries.

Evaluar el comportamiento real.

---

## Fase 7: UX/UI

Analizar:

- claridad de navegación;
- jerarquía visual;
- consistencia;
- legibilidad;
- densidad;
- escaneabilidad;
- CTAs;
- formularios;
- feedback visual;
- estados hover;
- estados focus;
- estados active;
- estados disabled;
- estados loading;
- estados empty;
- estados error;
- estados success;
- interacción móvil;
- comportamiento de modales y menús.

Las recomendaciones deben respetar:

- objetivo comercial;
- branding;
- audiencia;
- contenido existente.

No convertir todas las interfaces en el mismo estilo visual.

---

## Fase 8: Accesibilidad

Realizar una revisión inicial de:

- contraste;
- navegación mediante teclado;
- focus visible;
- etiquetas de formulario;
- texto alternativo;
- jerarquía de encabezados;
- semántica;
- botones accesibles;
- enlaces comprensibles;
- `aria-*` cuando corresponda;
- modales;
- menús;
- contenido oculto;
- zoom;
- animaciones.

Revisar especialmente:

`prefers-reduced-motion`

cuando el sitio utilice animaciones significativas.

Esta revisión es una auditoría inicial.

Cuando el proyecto requiera una auditoría especializada completa de accesibilidad, recomendar utilizar una Skill específica de accesibilidad.

---

## Fase 9: Animaciones y movimiento

Cuando el proyecto utilice:

- CSS animations;
- transitions;
- GSAP;
- ScrollTrigger;
- Three.js;
- WebGL;
- Canvas;
- partículas;
- parallax;
- efectos 3D;

analizar:

- propósito;
- suavidad;
- duración;
- consistencia;
- rendimiento;
- interacción;
- accesibilidad;
- comportamiento móvil;
- impacto sobre lectura;
- impacto sobre conversión.

Una animación visualmente atractiva no debe considerarse automáticamente una mejora.

Priorizar:

experiencia + rendimiento + accesibilidad + objetivo comercial.

---

## Fase 10: Rendimiento

Realizar una revisión inicial de:

- tamaño de imágenes;
- formatos;
- lazy loading;
- scripts;
- CSS;
- fuentes;
- dependencias;
- recursos bloqueantes;
- carga diferida;
- animaciones pesadas;
- DOM excesivo;
- assets duplicados;
- caché cuando pueda determinarse;
- posibles problemas de Core Web Vitals.

Diferenciar hallazgos medidos de estimaciones.

No afirmar métricas exactas que no hayan sido medidas.

Cuando sea necesaria una optimización profunda, recomendar una Skill especializada de performance.

---

## Fase 11: SEO visible

Realizar una revisión inicial de:

- `title`;
- meta description;
- canonical;
- robots;
- viewport;
- headings;
- HTML semántico;
- imágenes;
- enlaces;
- contenido indexable;
- Open Graph;
- datos estructurados cuando existan.

Esta Skill identifica problemas.

La implementación SEO especializada debe delegarse posteriormente a la Skill correspondiente.

No inventar:

- keywords;
- URLs;
- dominios;
- datos comerciales;
- Schema;
- perfiles sociales.

---

## Fase 12: Formularios

Revisar:

- labels;
- placeholders;
- tipos de input;
- validación frontend;
- mensajes de error;
- mensajes de éxito;
- required;
- estados;
- UX;
- accesibilidad;
- prevención evidente de doble envío;
- comportamiento móvil.

Cuando exista backend, identificar riesgos visibles de integración sin atribuir al frontend garantías que correspondan al servidor.

---

## Fase 13: Seguridad frontend

Realizar únicamente una inspección superficial relacionada con frontend:

- secretos visibles;
- tokens expuestos;
- información sensible embebida;
- scripts externos sospechosos;
- dependencias potencialmente problemáticas;
- contenido HTML inseguro evidente;
- uso riesgoso de `innerHTML`;
- configuraciones públicas indebidas.

No reemplazar una auditoría de seguridad especializada.

Cuando se requiera seguridad profunda, delegar a las capacidades de seguridad disponibles.

Nunca reproducir secretos detectados.

---

## Fase 14: Mantenibilidad

Analizar:

- duplicación;
- responsabilidades mezcladas;
- archivos excesivamente grandes;
- componentes repetidos;
- nombres inconsistentes;
- deuda técnica evidente;
- dependencias innecesarias;
- comentarios obsoletos;
- código muerto evidente;
- estructura difícil de mantener.

No recomendar una refactorización grande si el beneficio no justifica el riesgo.

---

## Uso del navegador

Cuando esté disponible acceso a navegador y sea necesario para la auditoría:

1. abrir el sitio autorizado;
2. comprobar navegación;
3. comprobar interacciones;
4. revisar diferentes tamaños;
5. observar errores visibles;
6. revisar consola cuando sea posible;
7. comprobar formularios sin realizar acciones destructivas;
8. documentar problemas reproducibles.

No:

- comprar;
- enviar formularios reales;
- borrar información;
- crear cuentas;
- modificar datos;
- ejecutar acciones irreversibles;

salvo autorización explícita.

---

## Uso de comandos

Durante una auditoría pueden utilizarse comandos de solo lectura cuando ayuden a comprender el proyecto y estén permitidos por el entorno.

Ejemplos conceptuales:

- inspeccionar archivos;
- buscar referencias;
- consultar dependencias;
- revisar Git;
- revisar configuración;
- ejecutar herramientas de análisis no destructivas.

No ejecutar comandos que:

- modifiquen archivos;
- instalen dependencias;
- eliminen archivos;
- cambien configuración;
- alteren bases de datos;

durante una auditoría pura.

---

## Integración con Git

Cuando exista Git:

- comprobar el estado del repositorio;
- identificar cambios existentes;
- no modificarlos;
- no realizar commits;
- no cambiar ramas;
- no limpiar archivos;
- no resetear contenido.

Una auditoría debe dejar el working tree exactamente como estaba.

---

## Severidad

Clasificar hallazgos mediante:

### CRITICAL

Problemas que pueden provocar:

- pérdida de funcionalidad importante;
- exposición grave;
- bloqueo completo;
- daño relevante al proyecto.

### HIGH

Problemas significativos de:

- funcionalidad;
- UX;
- accesibilidad;
- rendimiento;
- arquitectura;
- responsive.

### MEDIUM

Problemas que deterioran:

- mantenibilidad;
- consistencia;
- experiencia;
- optimización;
- calidad técnica.

### LOW

Mejoras menores:

- refinamiento visual;
- limpieza;
- consistencia;
- oportunidades no urgentes.

No inflar artificialmente la severidad.

---

## Evidencia

Cada hallazgo debe diferenciar entre:

`COMPROBADO`

Existe evidencia directa.

`PROBABLE`

Existe evidencia técnica importante pero falta reproducción completa.

`RECOMENDACIÓN`

Es una mejora sugerida, no un defecto confirmado.

No presentar opiniones de diseño como errores objetivos.

---

## Formato del informe

La auditoría debe comenzar con:

### Resumen ejecutivo

Indicar:

- estado general;
- principales riesgos;
- fortalezas importantes;
- prioridad recomendada.

Después:

### Hallazgos

Para cada hallazgo incluir cuando sea posible:

**ID**

**Severidad**

**Estado de evidencia**

**Área**

**Archivo**

**Ubicación**

**Problema**

**Evidencia**

**Impacto**

**Recomendación**

No inventar números de línea si no están disponibles.

---

## Roadmap de mejoras

Después de los hallazgos crear un roadmap priorizado.

Usar:

`P0`

Corregir inmediatamente.

`P1`

Alta prioridad.

`P2`

Mejora importante.

`P3`

Optimización posterior.

Separar cuando corresponda:

- funcionalidad;
- UX/UI;
- responsive;
- accesibilidad;
- performance;
- SEO;
- mantenibilidad;
- animaciones.

---

## Relación con otras Skills

Esta Skill diagnostica.

No debe absorber toda la implementación.

Después de una auditoría pueden utilizarse Skills especializadas como:

- frontend;
- SEO;
- performance;
- accesibilidad;
- Laravel;
- QA;
- seguridad.

La auditoría debe indicar qué especialidad debería encargarse de cada corrección relevante.

---

## Regla de no modificación

Si la solicitud contiene palabras como:

- auditar;
- revisar;
- analizar;
- diagnosticar;
- evaluar;

y no existe una petición explícita de modificar:

NO modificar archivos.

NO instalar dependencias.

NO ejecutar formatters que cambien archivos.

NO realizar commits.

NO cambiar configuraciones.

---

## Cuando el usuario solicite implementar las mejoras

La auditoría termina cuando se entrega el diagnóstico.

Si después el usuario solicita implementar:

1. utilizar la auditoría como fuente de verdad;
2. seleccionar una prioridad o conjunto de hallazgos;
3. utilizar la Skill especializada apropiada;
4. realizar cambios de forma controlada;
5. validar;
6. revisar el diff.

No mezclar silenciosamente auditoría e implementación.

---

## Criterios de finalización

Una auditoría se considera completa cuando:

- se inspeccionó el alcance disponible;
- se distinguieron hechos de recomendaciones;
- los problemas tienen prioridad;
- no se realizaron modificaciones;
- se identificaron limitaciones de la auditoría;
- se indicó qué debe corregirse primero;
- existe un roadmap accionable.

Si alguna parte no pudo comprobarse, declararlo explícitamente.

Nunca inventar que una prueba fue ejecutada.