# PROXTEL AI Agency - CORE v2

## Estado

CORE v2 se encuentra en desarrollo sobre la rama `core-v2`.

El baseline anterior permanece protegido mediante el tag `pre-core-v2`.

## Principio arquitectonico

PROXTEL AI Agency es el sistema central.

Claude, Codex, Antigravity y futuros proveedores son motores conectados al CORE.

La Agencia es independiente de esos proveedores.

El conocimiento profesional reutilizable debe permanecer independiente del proveedor siempre que sea posible.

## Fuente de verdad

El repositorio `PROXTEL-AI-AGENCY` es la fuente maestra del sistema.

Los proyectos de clientes consumen capacidades de la Agencia, pero no deben convertirse en la fuente maestra de capacidades globales.

## Componentes

### agents/

Contiene definiciones de responsabilidades profesionales.

Un Agent representa una funcion profesional y puede coordinar Subagents especializados cuando la tarea lo justifique.

### skills/

Contiene la biblioteca maestra de capacidades especializadas.

`skills/base/` conserva temporalmente las Skills existentes anteriores a CORE v2 mientras son auditadas y evolucionadas.

Las areas definitivas se organizan en:

- core
- development
- documentation
- crm
- sales
- customer-service
- finance
- marketing
- pbx

### skills/_registry/

Contiene el registro machine-readable de las Skills y su estado dentro de la Agencia.

La existencia fisica de una Skill no significa automaticamente que este aprobada.

### external/

Zona controlada para Skills y recursos obtenidos desde fuentes externas.

Flujo obligatorio:

`SOURCE -> QUARANTINE -> AUDIT -> TEST -> DECISION`

Las decisiones permitidas son:

- APPROVED
- ADAPT
- REFERENCE-ONLY
- REJECTED

### workflows/

Contiene procesos coordinados de multiples pasos.

Un Workflow puede coordinar:

- Agents
- Subagents
- Skills
- Tools
- validaciones
- approvals

### standards/

Contiene reglas persistentes y transversales de la Agencia.

Los Standards tienen prioridad sobre preferencias particulares de Agents o Skills cuando exista conflicto.

### tools/

Contiene el registro de herramientas, capacidades ejecutables y conexiones MCP.

Una Tool proporciona capacidad de accion.

Una Skill aporta conocimiento o procedimiento para utilizar capacidades correctamente.

### adapters/

Resuelve diferencias especificas entre proveedores.

Adapters iniciales:

- Claude
- Codex
- Antigravity

Los adapters no deben convertirse en la fuente principal del conocimiento profesional de la Agencia.

### tests/

Contiene pruebas para:

- Skills
- Agents
- Workflows
- integraciones

### config/

Contiene configuracion machine-readable del CORE.

El archivo principal actual es:

`config/agency-manifest.json`

### docs/

Contiene documentacion humana de:

- arquitectura
- Agents
- Skills
- Workflows
- Tools
- decisiones

## Distribucion de Skills

PROXTEL AI Agency mantiene una fuente maestra.

Los proyectos reciben solamente las Skills necesarias.

Flujo conceptual:

`PROXTEL-AI-AGENCY -> Skill bundle -> PROJECT/.agents/skills/`

Una copia instalada en un proyecto no sustituye la fuente maestra.

## Proveedores

La arquitectura inicial contempla:

- Claude
- Codex
- Antigravity

La tarea determina el proveedor.

El proveedor no determina la arquitectura de la Agencia.

## Orden de implementacion

1. Development / Web / Software
2. Documentation
3. CRM
4. Sales
5. Customer Service
6. Finance
7. Marketing
8. PBX

Marketing y PBX se implementaran al final de la secuencia definida.

## Seguridad

Las auditorias deben comenzar en READ ONLY cuando sea posible.

Las operaciones de alto impacto requieren autorizacion explicita.

Nunca deben almacenarse secretos reales dentro de:

- Skills
- Agents
- Workflows
- Standards
- repositorio Git

## Git

`main`

representa el baseline estable anterior mientras CORE v2 se encuentra en construccion.

`pre-core-v2`

es el tag de recuperacion creado antes de iniciar CORE v2.

`core-v2`

es la rama activa de implementacion.

CORE v2 no debe fusionarse a `main` hasta superar las validaciones correspondientes.