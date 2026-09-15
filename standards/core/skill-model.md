# PROXTEL AI Agency — Modelo de Skills

## Definición

Una Skill es una capacidad especializada reutilizable.

Debe contener conocimiento, procedimientos, convenciones o recursos que mejoren de forma concreta la ejecución de un tipo de tarea.

## Principio

Una buena Skill debe tener una responsabilidad reconocible.

Evitar Skills gigantes que intenten resolver toda la Agencia.

## Una Skill puede contener

- SKILL.md;
- scripts;
- referencias;
- ejemplos;
- plantillas;
- recursos.

Solamente deben añadirse componentes necesarios.

## No todo es una Skill

Utilizar:

Standard
para reglas persistentes y universales.

Workflow
para procesos coordinados de múltiples pasos.

Tool
para una capacidad ejecutable.

MCP
para conectar herramientas o fuentes externas.

Agent
para una responsabilidad profesional.

Adapter
para diferencias específicas de proveedor.

Skill
para conocimiento o procedimiento especializado reutilizable.

## Skills globales

Las capacidades aplicables a múltiples proyectos viven en la biblioteca maestra de la Agencia.

Ejemplos:

- Laravel;
- MySQL;
- SEO;
- accesibilidad;
- QA;
- frontend;
- seguridad.

## Skills específicas de proyecto

El conocimiento exclusivo de un proyecto puede vivir dentro de su workspace.

Ejemplos:

- reglas de negocio propias;
- API privada particular;
- arquitectura exclusiva;
- procedimiento específico de despliegue.

## Fuente maestra

Una Skill PROXTEL reutilizable debe tener una única fuente maestra.

Las copias instaladas en proyectos o proveedores son distribuciones de esa fuente.

## Identidad

Toda Skill debe tener como mínimo:

- nombre técnico;
- descripción;
- propósito;
- alcance;
- trigger o condiciones de uso;
- límites;
- procedimiento;
- criterios de finalización.

## Nombres

Preferir identificadores técnicos:

- simples;
- estables;
- en minúsculas;
- con guiones;
- sin espacios;
- sin caracteres problemáticos para CLI.

Los títulos visibles pueden estar en español.

## Evolución

Una Skill puede:

- crearse;
- auditarse;
- probarse;
- versionarse;
- mejorarse;
- dividirse;
- deprecarse;
- sustituirse.

Los cambios importantes deben probarse antes de distribuirse.

## Evidencia

Las Skills que realizan auditorías deben distinguir claramente:

- COMPROBADO;
- PROBABLE;
- RECOMENDACIÓN.

## Seguridad

Una Skill no debe contener:

- secretos;
- contraseñas;
- tokens reales;
- claves API reales;
- claves privadas;
- credenciales de producción.

## Scripts

Un script incorporado dentro de una Skill debe ser tratado como código ejecutable.

Antes de aprobarlo revisar:

- operaciones de archivos;
- comandos shell;
- red;
- procesos;
- dependencias;
- permisos;
- acciones destructivas;
- tratamiento de secretos.

## Testing

Las Skills importantes deben disponer de casos de prueba.

Cuando sea posible comparar:

sin Skill
vs
con Skill

para validar que la Skill realmente mejora:

- calidad;
- precisión;
- consistencia;
- seguridad;
- eficiencia.

## Skills externas

Ninguna Skill externa se convierte automáticamente en Skill PROXTEL.

Debe pasar por la política de Skills externas.