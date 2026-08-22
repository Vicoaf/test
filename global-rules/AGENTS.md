# PROXTEL / Agencia IA - Reglas globales de Codex

## Idioma

- Interactuar con el usuario en español.
- Los nombres técnicos, comandos, clases, métodos y APIs pueden conservar su idioma original cuando corresponda.

## Principios generales

- No asumir información que no exista en el proyecto.
- No inventar credenciales, URLs, dominios, claves, IDs, endpoints ni datos de producción.
- Inspeccionar primero el repositorio antes de realizar modificaciones.
- Entender la arquitectura existente antes de proponer cambios.
- Mantener compatibilidad con el stack existente.
- Respetar el branding, diseño y comportamiento actual salvo que la tarea solicite explícitamente modificarlo.
- No eliminar funcionalidades existentes sin una razón técnica justificada y autorización explícita.
- No modificar archivos fuera del alcance solicitado.

## Código

- Priorizar código claro, mantenible y seguro.
- Seguir las convenciones oficiales del framework utilizado.
- Evitar duplicación innecesaria.
- No introducir dependencias nuevas si existe una solución razonable con las dependencias actuales.
- Antes de instalar una nueva dependencia de producción, explicar por qué es necesaria.
- No dejar código temporal, comentarios TODO innecesarios, debugging, console.log o dumps en código terminado.
- No truncar archivos.
- No utilizar marcadores como:
  - resto del código
  - código existente
  - ...
  - TODO implementar después

## Seguridad

- Nunca mostrar, almacenar o incluir secretos en el código.
- No modificar archivos .env salvo autorización explícita.
- Nunca incluir:
  - contraseñas
  - tokens
  - API keys
  - claves privadas
  - secretos de producción
- Validar entradas del usuario.
- Aplicar autorización además de autenticación cuando corresponda.
- Revisar riesgos de:
  - SQL Injection
  - XSS
  - CSRF
  - IDOR
  - Mass Assignment
  - subida insegura de archivos
  - exposición de información sensible

## Git

- Revisar el estado de Git antes de realizar cambios importantes.
- No ejecutar git reset --hard sin autorización.
- No sobrescribir trabajo existente del usuario.
- No realizar force push.
- No cambiar de rama ni hacer merge sin autorización cuando pueda afectar trabajo existente.
- Revisar git diff antes de considerar terminada una modificación.

## Laravel / PHP

Cuando el proyecto utilice Laravel:

- Seguir las convenciones oficiales de Laravel.
- Utilizar Form Requests cuando la validación sea suficientemente compleja.
- Utilizar Policies o Gates para autorización cuando corresponda.
- Evitar lógica de negocio compleja dentro de Controllers.
- Evitar consultas N+1.
- Revisar índices de base de datos cuando sean relevantes.
- Utilizar transacciones para operaciones que deban ser atómicas.
- No modificar migraciones ya aplicadas en producción salvo que la tarea lo requiera expresamente.
- Preferir nuevas migraciones para cambios de esquema.
- Ejecutar pruebas disponibles después de cambios relevantes.

## Frontend

- Utilizar HTML semántico.
- Mantener diseño responsive y mobile-first.
- Respetar el sistema visual existente del proyecto.
- No imponer tipografías, colores o frameworks diferentes si el proyecto ya tiene branding.
- Evitar CSS inline salvo necesidad técnica justificada.
- Mantener accesibilidad.
- Respetar prefers-reduced-motion cuando existan animaciones importantes.
- Evitar animaciones que perjudiquen rendimiento, lectura o interacción.
- Optimizar imágenes y recursos cuando sea apropiado.
- Evitar JavaScript innecesario.

## Bootstrap

Cuando el proyecto utilice Bootstrap:

- Utilizar correctamente grid, utilities y componentes.
- Evitar sobrescribir Bootstrap innecesariamente.
- Mantener consistencia responsive.
- No agregar Tailwind u otro framework CSS salvo solicitud expresa.

## JavaScript

- Evitar variables globales innecesarias.
- Manejar errores correctamente.
- No introducir librerías cuando JavaScript nativo sea suficiente.
- Revisar errores de consola después de cambios relevantes.

## Base de datos

- No borrar tablas, columnas o datos sin autorización explícita.
- No ejecutar operaciones destructivas sobre bases de datos de producción.
- Revisar relaciones, claves foráneas e índices.
- Evitar queries innecesariamente costosas.
- No asumir estructura de tablas sin inspeccionarla.

## APIs e integraciones

- Validar payloads de entrada.
- Manejar correctamente timeouts y errores.
- No asumir respuestas externas.
- Verificar autenticación y autorización.
- Para webhooks, verificar firma o mecanismo equivalente cuando el proveedor lo soporte.
- Evitar registrar información sensible en logs.

## Auditorías

Si el usuario solicita auditar, revisar o analizar:

- No modificar archivos salvo autorización expresa.
- Separar hallazgos en:
  - CRITICAL
  - HIGH
  - MEDIUM
  - LOW
- Para cada hallazgo indicar:
  - archivo
  - ubicación
  - problema
  - impacto
  - recomendación

## Verificación obligatoria

Antes de considerar una tarea terminada:

1. Revisar los archivos modificados.
2. Revisar git diff cuando Git esté disponible.
3. Ejecutar las pruebas relevantes disponibles.
4. Ejecutar lint cuando exista.
5. Ejecutar build cuando corresponda.
6. Revisar errores generados durante las pruebas.
7. Informar cualquier prueba que no haya podido ejecutarse.
8. Enumerar claramente los archivos modificados.

## Producción

- No desplegar directamente a producción salvo instrucción explícita.
- Preferir:
  desarrollo local -> pruebas -> staging -> producción.
- No ejecutar operaciones destructivas en producción sin autorización explícita.
