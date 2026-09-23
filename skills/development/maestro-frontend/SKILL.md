---
name: maestro-frontend
description: Disena, implementa y refactoriza frontend profesional respetando branding, contenido, stack y arquitectura existentes. Usala para HTML, CSS, JavaScript, Blade, Bootstrap, Vite, responsive, accesibilidad, motion y 3D justificado.
---

# PROXTEL Maestro Frontend

## Mision

Crear y mejorar interfaces profesionales, responsivas, accesibles, mantenibles y visualmente coherentes con cada marca.

No imponer una estetica generica a todos los clientes.

## Flujo

inspeccionar -> entender branding y stack -> planear -> implementar localmente -> validar -> revisar diff

## Proyectos existentes

Antes de modificar:

1. leer reglas del proyecto;
2. identificar stack, layouts y componentes;
3. revisar estilos globales y design tokens;
4. revisar JavaScript y dependencias;
5. revisar responsive actual;
6. revisar Git y cambios sin confirmar;
7. limitar el cambio al alcance pedido.

No reestructurar todo el proyecto para resolver un problema localizado.

## Proyectos nuevos

Definir primero:

- requisitos;
- branding;
- contenido;
- arquitectura;
- stack;
- sistema visual;
- responsive;
- componentes;
- validacion.

Las decisiones propuestas deben distinguirse de requisitos proporcionados.

## Branding y contenido

Preservar logos, colores, tipografias, iconografia, recursos y contenido aprobado.

No reemplazar assets reales con placeholders sin solicitud expresa.

No inventar testimonios, clientes, certificaciones, cifras ni caracteristicas comerciales.

## HTML

Preferir HTML semantico, jerarquia de headings coherente, labels correctos y controles apropiados.

## CSS

Preferir variables, tokens y componentes reutilizables existentes.

Evitar especificidad excesiva, !important innecesario, duplicacion y hacks sin justificacion.

## JavaScript

Usar JavaScript para comportamiento real.

Evitar listeners duplicados, globals innecesarios, manipulacion excesiva del DOM y debugging residual.

Manejar errores y estados de interfaz.

## Bootstrap / Blade / Vite

Si el proyecto ya los usa, preservar su arquitectura.

No migrar entre CDN/npm ni introducir otro framework sin necesidad demostrada.

## Responsive

Validar comportamiento real en breakpoints relevantes.

Revisar especialmente navegacion, hero, tarjetas, tablas, formularios, modales, overflow y elementos fixed/sticky.

## Accesibilidad

Aplicar semantica, teclado, focus visible, contraste, labels, alt text y reduced motion cuando corresponda.

Usar automatizacion y revision manual proporcional.

## Motion

CSS primero cuando sea suficiente.

Usar GSAP para secuencias complejas justificadas.

Usar Three.js/WebGL solo cuando el valor visual compense bundle, GPU, bateria, mobile, accesibilidad y Core Web Vitals.

## Performance

Cuidar imagenes, fuentes, CSS, JavaScript, dependencias, renderizado y assets.

Cuando sea material, validar Lighthouse/Core Web Vitals incluyendo LCP, INP y CLS.

## Dependencias

No instalar dependencias de produccion silenciosamente.

Preferir capacidades ya presentes cuando resuelvan el problema razonablemente.

## Validacion

Despues de modificar:

- revisar archivos;
- revisar diff;
- ejecutar tests relacionados;
- ejecutar lint;
- ejecutar build;
- realizar browser/responsive checks cuando aplique;
- revisar accesibilidad/performance proporcionalmente;
- corregir errores introducidos;
- reportar validaciones no ejecutadas.

## Git y produccion

No commit automatico.

No push automatico.

No deploy automatico.

No operaciones destructivas de produccion.

## Finalizacion

La entrega queda lista cuando el alcance fue implementado, las validaciones aplicables pasan o estan declaradas, el contenido/branding autorizado se conserva y no quedan errores introducidos conocidos.