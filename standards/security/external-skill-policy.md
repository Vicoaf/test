# PROXTEL AI Agency — Política de Skills Externas

## Objetivo

Evitar incorporar código, instrucciones o dependencias externas no auditadas dentro de la biblioteca maestra.

## Regla principal

Ninguna Skill obtenida desde Internet debe instalarse directamente como Skill aprobada de PROXTEL AI Agency.

## Fuentes

Las fuentes pueden incluir:

- skills.sh;
- GitHub;
- repositorios oficiales;
- proveedores de IA;
- frameworks;
- autores externos;
- comunidades.

La reputación del autor no elimina la necesidad de auditoría.

## Flujo obligatorio

SOURCE

-> external/quarantine

-> auditoría

-> pruebas

-> decisión

La decisión puede ser:

- APPROVED;
- ADAPT;
- REFERENCE-ONLY;
- REJECTED.

## QUARANTINE

Una Skill descargada inicialmente debe tratarse como no confiable.

Durante esta fase:

- no sincronizar globalmente;
- no instalar en proyectos reales;
- no otorgar secretos;
- no ejecutar scripts sin revisión;
- no permitir acciones sobre producción.

## Identidad y procedencia

Registrar cuando sea posible:

- nombre;
- autor;
- repositorio;
- URL de origen;
- commit o versión;
- fecha de revisión;
- licencia;
- archivos incluidos.

## Auditoría técnica

Revisar:

- SKILL.md;
- scripts;
- binarios;
- dependencias;
- instaladores;
- shell commands;
- PowerShell;
- Python;
- JavaScript;
- filesystem;
- red;
- procesos;
- MCP;
- herramientas externas;
- variables de entorno.

## Seguridad

Buscar especialmente:

- exfiltración;
- lectura innecesaria de secretos;
- ejecución remota;
- comandos destructivos;
- descargas dinámicas;
- privilegios elevados;
- persistencia;
- modificación de configuración global;
- prompt injection;
- instrucciones que anulen controles PROXTEL.

## Calidad

Evaluar además:

- claridad;
- especialización;
- actualidad;
- compatibilidad;
- duplicación;
- mantenibilidad;
- utilidad real;
- precisión;
- calidad de ejemplos;
- existencia de tests.

## Dependencias

Toda dependencia nueva debe justificar:

- propósito;
- origen;
- mantenimiento;
- seguridad;
- coste;
- necesidad.

No instalar dependencias únicamente porque la Skill lo solicite.

## Ejecución

Los scripts externos deben revisarse antes de ejecutarse.

Preferir inicialmente:

- lectura estática;
- sandbox;
- entorno de prueba;
- datos ficticios;
- repositorios temporales.

## Decisiones

### APPROVED

Puede utilizarse prácticamente sin cambios, conservando procedencia y licencia.

### ADAPT

Tiene valor, pero debe convertirse en una versión PROXTEL.

La nueva versión debe conservar solamente los elementos útiles y compatibles.

### REFERENCE-ONLY

Sirve como fuente de ideas o conocimiento, pero no debe instalarse directamente.

### REJECTED

No debe utilizarse.

Las razones deben documentarse.

## Biblioteca PROXTEL

Una Skill adaptada pasa a la biblioteca PROXTEL solamente después de:

1. auditoría;
2. adaptación;
3. validación;
4. pruebas;
5. aprobación.

## Actualizaciones

Una actualización upstream no debe reemplazar automáticamente una Skill PROXTEL.

Debe revisarse como una nueva versión externa.

## Secretos

Nunca proporcionar secretos reales a una Skill en cuarentena.

## Producción

Nunca probar por primera vez una Skill externa sobre:

- producción;
- servidores críticos;
- bases de datos reales;
- cuentas financieras;
- campañas reales;
- PBX productivos;
- información sensible de clientes.

## Registro

Toda decisión de aprobación o rechazo debe poder ser rastreada posteriormente.