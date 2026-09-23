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

### Versionado funcional

`schema_version` y `lifecycle.version` representan conceptos distintos.

`schema_version` identifica la versión del contrato o estructura machine-readable de PROXTEL.

`lifecycle.version` identifica la versión funcional de una Skill concreta.

Las Skills PROXTEL utilizarán Semantic Versioning con el formato:

`MAJOR.MINOR.PATCH`

#### PATCH

Incrementar PATCH para correcciones compatibles que no amplíen de forma material el alcance, triggers, responsabilidades o capacidades de la Skill.

Ejemplos:

- correcciones de redacción;
- aclaraciones no funcionales;
- corrección de una instrucción errónea;
- ajustes compatibles de validación.

#### MINOR

Incrementar MINOR cuando se agreguen capacidades, procedimientos, reglas, triggers compatibles o criterios de validación sin romper el comportamiento esperado previamente aprobado.

Ejemplos:

- nueva capacidad compatible;
- nuevo tipo de escenario soportado;
- nuevas validaciones;
- ampliación compatible de un procedimiento.

#### MAJOR

Incrementar MAJOR cuando exista un cambio incompatible que modifique de forma material el contrato funcional esperado de la Skill.

Ejemplos:

- eliminar capacidades previamente soportadas;
- cambiar de forma incompatible sus triggers o non-triggers;
- cambiar responsabilidades o alcance de manera incompatible;
- modificar el comportamiento esperado de una forma que requiera adaptación de consumidores existentes.

### Actualización de Skills aprobadas

Una Skill `approved` no debe modificarse silenciosamente como si la nueva revisión conservara la misma identidad de versión.

Toda actualización material debe:

1. partir de la versión aprobada existente;
2. determinar el incremento MAJOR, MINOR o PATCH;
3. producir una nueva `candidate`;
4. preservar la evidencia de la versión aprobada anterior;
5. ejecutar las pruebas y comparaciones aplicables;
6. pasar por Auditor independiente;
7. promoverse solamente mediante la transición de gobernanza correspondiente.

La creación de una candidate no reemplaza ni invalida por sí misma la versión `approved` actualmente distribuida.

Nunca reutilizar un número de versión para contenido funcionalmente diferente.

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
