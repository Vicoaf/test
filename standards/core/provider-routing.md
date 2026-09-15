# PROXTEL AI Agency — Provider Routing

## Objetivo

Definir cómo seleccionar el motor de inteligencia artificial adecuado sin acoplar la Agencia a un proveedor específico.

## Principio

La tarea determina el proveedor.

El proveedor no determina la arquitectura de la Agencia.

## Proveedores principales

La arquitectura inicial contempla:

- Claude;
- Codex;
- Antigravity.

Pueden añadirse otros proveedores en el futuro mediante nuevos adapters.

## Claude

Uso preferente inicial para:

- arquitectura;
- planificación;
- razonamiento transversal;
- diseño de sistemas;
- revisión conceptual compleja;
- documentación extensa;
- coordinación de procesos largos;
- análisis de tradeoffs.

No constituye un límite rígido.

## Codex

Uso preferente inicial para:

- implementación;
- programación;
- refactorización;
- modificación de repositorios;
- creación de pruebas;
- debugging;
- scripts;
- automatización técnica;
- trabajo directo con código.

No constituye un límite rígido.

## Antigravity

Uso preferente inicial para:

- investigación;
- auditorías independientes;
- análisis paralelo;
- revisión visual;
- navegación;
- comprobaciones externas;
- ejecución coordinada de agentes cuando resulte apropiado.

No constituye un límite rígido.

## Selección

Antes de seleccionar proveedor considerar:

1. naturaleza de la tarea;
2. riesgo;
3. necesidad de herramientas;
4. tamaño del contexto;
5. necesidad de navegador;
6. necesidad de modificar código;
7. necesidad de auditoría independiente;
8. coste adicional;
9. disponibilidad del proveedor;
10. restricciones del entorno.

## Política de costes

Priorizar las capacidades ya incluidas en las suscripciones disponibles.

No introducir consumo adicional de API, infraestructura o servicios pagados sin necesidad y autorización.

## Validación cruzada

Para cambios importantes, preferir que la revisión crítica sea realizada por una entidad distinta de la que produjo la implementación.

Patrones posibles:

Claude
-> diseña
-> Codex implementa
-> Antigravity audita

o:

Codex
-> implementa
-> Antigravity prueba
-> Claude revisa arquitectura

La separación busca reducir errores correlacionados.

## Fallback

Si el proveedor preferente no está disponible:

1. evaluar si otro proveedor puede realizar correctamente la tarea;
2. conservar las mismas reglas PROXTEL;
3. no degradar silenciosamente controles de seguridad;
4. informar limitaciones importantes.

## Adapter

Las diferencias específicas de cada proveedor deben resolverse principalmente dentro de:

adapters/

El conocimiento profesional reutilizable debe permanecer fuera de adapters siempre que sea posible.

## Prohibición de duplicación innecesaria

No mantener tres versiones divergentes de una misma Skill únicamente para Claude, Codex y Antigravity.

Mantener una fuente maestra cuando sea técnicamente posible y crear adapters de compatibilidad cuando sean necesarios.