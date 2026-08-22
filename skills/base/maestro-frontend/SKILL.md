---
name: maestro-frontend
description: Diseña, desarrolla, mejora y refactoriza frontend profesional para sitios web y aplicaciones existentes o nuevas, respetando el branding, stack y arquitectura del proyecto. Trabaja con HTML, CSS, JavaScript, Bootstrap, Blade/Laravel, Vite y tecnologías de animación como GSAP o Three.js cuando estén justificadas. Úsala cuando el usuario solicite crear, implementar, modernizar o mejorar interfaces, landing pages, sitios corporativos, dashboards, CRM o frontend SaaS. Interactúa en español.
---

# Maestro Frontend Profesional

## Objetivo

Diseñar, construir y mejorar interfaces web profesionales, modernas, responsivas, accesibles, mantenibles y visualmente atractivas.

El objetivo no es producir efectos visuales por sí mismos.

El objetivo es combinar:

- diseño;
- claridad;
- identidad de marca;
- experiencia de usuario;
- conversión;
- rendimiento;
- accesibilidad;
- mantenibilidad;
- compatibilidad técnica.

La Skill debe adaptarse al proyecto existente.

No debe obligar al proyecto a adaptarse a preferencias arbitrarias de la Skill.

---

# Principio fundamental

Antes de modificar:

inspeccionar -> comprender -> planear -> implementar -> validar

Nunca comenzar reescribiendo un frontend existente sin entender primero:

- arquitectura;
- stack;
- branding;
- estilos;
- componentes;
- dependencias;
- comportamiento;
- restricciones.

---

# Prioridad de decisiones

Cuando existan varias posibles decisiones de diseño o implementación, utilizar este orden:

1. instrucciones explícitas del usuario;
2. reglas específicas del proyecto;
3. branding del cliente;
4. design system existente;
5. arquitectura existente;
6. stack existente;
7. accesibilidad;
8. rendimiento;
9. mantenibilidad;
10. buenas prácticas del ecosistema;
11. preferencias visuales de la Skill.

Nunca imponer:

- colores;
- tipografías;
- frameworks;
- librerías;
- estilos;
- animaciones;

si contradicen el proyecto.

---

# Alcance

Esta Skill puede trabajar con:

- HTML5;
- CSS;
- SCSS/SASS;
- JavaScript;
- Bootstrap;
- PHP frontend;
- Laravel Blade;
- Vite;
- SVG;
- Canvas;
- GSAP;
- ScrollTrigger;
- Three.js;
- WebGL;
- Swiper;
- librerías frontend ya existentes en el proyecto.

También puede trabajar sobre:

- landing pages;
- sitios corporativos;
- portales;
- dashboards;
- CRM;
- paneles administrativos;
- interfaces SaaS;
- páginas de producto;
- aplicaciones web.

---

# Adaptación al stack

Antes de implementar, identificar el stack real.

No asumir automáticamente:

- Bootstrap;
- Laravel;
- React;
- Vue;
- Tailwind;
- GSAP;
- Three.js;
- jQuery;
- Vite.

Si el proyecto utiliza Bootstrap, continuar utilizando Bootstrap salvo motivo técnico justificado.

Si utiliza Blade, preservar la arquitectura Blade.

Si utiliza JavaScript vanilla, no introducir un framework completo sin necesidad.

Si utiliza un sistema visual existente, reutilizarlo.

---

# Proyectos existentes

Cuando el proyecto ya esté desarrollado:

1. inspeccionar archivos relevantes;
2. identificar componentes compartidos;
3. identificar estilos globales;
4. identificar variables o design tokens;
5. identificar JavaScript existente;
6. identificar dependencias;
7. identificar responsive actual;
8. comprobar Git cuando esté disponible;
9. revisar cambios sin confirmar;
10. limitar la modificación al alcance solicitado.

No reestructurar todo el proyecto para resolver un problema localizado.

---

# Proyectos nuevos

Cuando se trate de un frontend nuevo:

1. revisar requisitos;
2. revisar branding;
3. revisar contenido;
4. revisar arquitectura prevista;
5. determinar stack;
6. establecer sistema visual;
7. desarrollar mobile-first;
8. implementar componentes;
9. implementar comportamiento;
10. validar.

Cuando no exista branding suficiente, se pueden realizar propuestas claramente identificadas como propuestas.

No presentar decisiones inventadas como requisitos del cliente.

---

# Branding

Respetar:

- logotipo;
- paleta;
- tipografía;
- personalidad;
- tono visual;
- iconografía;
- fotografías;
- recursos entregados;
- guía de marca.

No sustituir recursos existentes por placeholders.

Si falta un recurso necesario:

reportar el asset faltante.

No utilizar automáticamente:

- Unsplash;
- Lorem Picsum;
- via.placeholder.com;
- imágenes generadas;
- fotografías aleatorias;

salvo solicitud expresa.

---

# Diseño visual

Buscar una apariencia profesional y coherente mediante:

- jerarquía visual;
- whitespace;
- escala tipográfica;
- contraste;
- alineación;
- ritmo;
- profundidad;
- consistencia;
- estados interactivos;
- microinteracciones.

No utilizar una estética genérica idéntica para todos los clientes.

Evitar convertir todas las interfaces en:

- glassmorphism;
- gradients;
- dark mode;
- neon;
- cards flotantes;
- rounded everything;

si no corresponde a la identidad del proyecto.

---

# Espaciado

Utilizar un sistema consistente de espaciado.

Puede basarse en:

- escala de 4px;
- escala de 8px;
- tokens existentes;
- utilities del framework.

No imponer obligatoriamente una cuadrícula de 8px si el proyecto utiliza otro sistema coherente.

La consistencia es más importante que una cifra específica.

---

# Tipografía

Usar primero la tipografía definida por el branding o proyecto.

Si no existe:

proponer alternativas justificadas.

No imponer automáticamente:

- Inter;
- Plus Jakarta Sans;
- Poppins;
- Montserrat;

solo por preferencia.

Considerar:

- legibilidad;
- pesos disponibles;
- carga;
- idioma;
- jerarquía;
- performance.

---

# HTML

Utilizar HTML semántico cuando corresponda:

- `header`;
- `nav`;
- `main`;
- `section`;
- `article`;
- `aside`;
- `footer`.

Mantener:

- jerarquía lógica H1-H6;
- labels correctos;
- botones para acciones;
- enlaces para navegación;
- atributos apropiados;
- estructura comprensible.

Evitar divs innecesarios.

No romper el contenido original.

---

# Fidelidad de contenido

Cuando el usuario proporcione contenido aprobado:

- conservarlo;
- no resumirlo;
- no eliminar párrafos;
- no cambiar cifras;
- no inventar testimonios;
- no inventar clientes;
- no inventar certificaciones;
- no inventar características comerciales.

Si una mejora editorial pudiera beneficiar al proyecto, proponerla separadamente.

No modificar contenido comercial aprobado de forma silenciosa.

---

# Bootstrap

Cuando el proyecto utilice Bootstrap:

preferir:

- containers;
- grid;
- utilities;
- componentes existentes;
- breakpoints nativos;

antes de recrear manualmente funciones equivalentes.

Evitar:

- overrides innecesarios;
- exceso de `!important`;
- duplicación de utilities;
- clases contradictorias.

No utilizar Bootstrap CDN si el proyecto ya utiliza npm/Vite.

No migrar Bootstrap de npm a CDN ni viceversa sin motivo.

---

# CSS

Preferir una estructura mantenible.

Utilizar cuando estén disponibles:

- CSS variables;
- design tokens;
- clases reutilizables;
- componentes;
- estilos globales bien delimitados.

Evitar:

- especificidad excesiva;
- selectores frágiles;
- `!important` innecesario;
- duplicación;
- estilos muertos;
- hacks sin explicación.

Evitar CSS inline salvo necesidad técnica justificada o requerimiento del sistema existente.

---

# JavaScript

Utilizar JavaScript para comportamiento real, no para funciones que CSS puede resolver de forma sencilla.

Evitar:

- variables globales innecesarias;
- listeners duplicados;
- scripts bloqueantes;
- manipulación excesiva del DOM;
- dependencias innecesarias;
- código duplicado.

Manejar correctamente:

- errores;
- estados;
- promesas;
- eventos;
- componentes dinámicos.

No dejar:

- `console.log`;
- debugging temporal;
- código experimental;

en la entrega final salvo necesidad explícita.

---

# Animaciones

Las animaciones deben tener propósito.

Pueden utilizarse para:

- reforzar jerarquía;
- orientar al usuario;
- comunicar estados;
- mejorar percepción de calidad;
- crear narrativa;
- aumentar engagement.

No utilizar animación únicamente para demostrar capacidad técnica.

---

# Animaciones CSS

Preferir CSS cuando sea suficiente para:

- hover;
- focus;
- active;
- fades;
- transforms;
- pequeños reveals;
- microinteracciones.

---

# GSAP

Utilizar GSAP solamente cuando aporte valor real.

Casos apropiados:

- timelines complejas;
- scroll storytelling;
- secuencias coordinadas;
- animaciones complejas;
- ScrollTrigger;
- control preciso.

No añadir GSAP solo para animar elementos que pueden resolverse razonablemente con CSS.

Si GSAP no está instalado, no incorporarlo automáticamente a un proyecto existente sin evaluar el impacto.

---

# Three.js y WebGL

Utilizar Three.js/WebGL solamente cuando la experiencia visual lo justifique.

Ejemplos:

- hero 3D;
- objetos interactivos;
- escenas tridimensionales;
- partículas avanzadas;
- visualizaciones.

Antes de utilizarlo considerar:

- tamaño del bundle;
- GPU;
- dispositivos móviles;
- batería;
- accesibilidad;
- fallback;
- Core Web Vitals.

No convertir una página corporativa en una experiencia WebGL innecesariamente.

---

# Motion accessibility

Cuando existan animaciones relevantes, respetar:

`prefers-reduced-motion`

Ejemplo conceptual:

```css
@media (prefers-reduced-motion: reduce) {
    *,
    *::before,
    *::after {
        scroll-behavior: auto !important;
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
    }
}