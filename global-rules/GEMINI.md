# PROXTEL / Agencia IA - Estándares globales de desarrollo

## Idioma

- Responder e interactuar siempre en español.
- Los nombres técnicos, comandos, clases, métodos, APIs, paquetes y términos oficiales pueden conservarse en inglés cuando corresponda.

## Principios generales

- No inventar datos, credenciales, URLs, dominios, endpoints, IDs, recursos, configuraciones ni información de producción.
- No asumir información que pueda comprobarse inspeccionando el proyecto.
- Antes de modificar un proyecto existente, inspeccionar primero su arquitectura, estructura, tecnologías y convenciones.
- Mantener compatibilidad con el stack existente salvo que se solicite explícitamente una migración.
- Respetar el branding, diseño, arquitectura y comportamiento existentes salvo que la tarea indique expresamente modificarlos.
- No eliminar funcionalidades existentes sin autorización explícita.
- No modificar archivos fuera del alcance solicitado.
- No realizar cambios innecesarios mientras se resuelve una tarea puntual.

## Protección del código existente

- No sobrescribir trabajo existente sin inspeccionarlo previamente.
- No eliminar código simplemente porque parezca no utilizado sin comprobar dependencias y referencias.
- No reemplazar archivos completos cuando una modificación localizada sea suficiente.
- No truncar archivos.
- No utilizar marcadores como:
  - resto del código
  - código existente
  - ...
  - implementar después
- Cuando el usuario solicite un archivo completo, entregar el archivo íntegro.
- Cuando se trabaje directamente sobre un repositorio, modificar los archivos necesarios en lugar de imprimir innecesariamente archivos completos en el chat.

## Seguridad

- Nunca escribir credenciales, contraseñas, tokens, claves API, claves privadas o secretos dentro del repositorio.
- Nunca modificar archivos `.env` salvo autorización explícita.
- Nunca mostrar secretos existentes encontrados durante una inspección.
- Si se detecta información sensible expuesta, reportarla sin reproducir su valor.
- No reducir controles de seguridad existentes para resolver temporalmente un problema.
- No desactivar autenticación, autorización, validaciones, CSRF, políticas de seguridad o controles equivalentes sin autorización explícita.

## Git y control de cambios

- Antes de realizar cambios importantes, comprobar si el proyecto utiliza Git.
- Cuando Git esté disponible, revisar el estado del repositorio antes de modificar.
- No ejecutar `git reset --hard`.
- No ejecutar `git clean -fd`.
- No realizar `force push`.
- No eliminar ramas.
- No cambiar de rama, fusionar ramas ni reescribir historial sin autorización cuando pueda afectar trabajo existente.
- No sobrescribir cambios no confirmados del usuario.
- Revisar el diff antes de considerar terminada una tarea.

## Auditorías

- Cuando el usuario solicite auditar, revisar, analizar o diagnosticar, trabajar inicialmente en modo solo lectura.
- No modificar archivos durante una auditoría salvo autorización explícita.
- Separar los hallazgos por severidad cuando sea apropiado:
  - CRITICAL
  - HIGH
  - MEDIUM
  - LOW
- Para cada hallazgo indicar, cuando sea posible:
  - archivo
  - ubicación
  - problema
  - impacto
  - solución recomendada
- Diferenciar claramente hechos comprobados de recomendaciones.

## Ejecución y herramientas

- Antes de ejecutar comandos potencialmente destructivos, evaluar su impacto.
- No ejecutar comandos destructivos sobre datos o archivos sin autorización explícita.
- Preferir comandos verificables y reversibles.
- No instalar nuevas dependencias de producción si existe una solución razonable utilizando las dependencias actuales.
- Si una nueva dependencia es necesaria, explicar su propósito antes de incorporarla cuando tenga impacto relevante en el proyecto.

## Validación obligatoria

Después de realizar modificaciones:

1. Revisar los archivos modificados.
2. Revisar el diff cuando Git esté disponible.
3. Ejecutar las pruebas disponibles relacionadas con el cambio.
4. Ejecutar lint cuando exista.
5. Ejecutar build cuando corresponda.
6. Revisar errores producidos por las herramientas.
7. Corregir errores introducidos por los cambios realizados.
8. Reportar cualquier validación que no haya podido ejecutarse.
9. Informar claramente qué archivos fueron modificados.

## Producción

- No desplegar directamente a producción salvo instrucción explícita.
- No ejecutar operaciones destructivas sobre bases de datos de producción.
- No modificar servidores de producción como parte de una tarea de desarrollo local salvo solicitud expresa.
- Preferir el flujo:
  desarrollo local -> pruebas -> staging -> producción.

## Prioridad de instrucciones

Cuando existan instrucciones adicionales específicas del proyecto:

1. Respetar las instrucciones explícitas del usuario.
2. Respetar las reglas específicas del proyecto.
3. Aplicar estas reglas globales.
4. Aplicar las Skills especializadas correspondientes.

Si existe una contradicción importante entre instrucciones, detener la modificación afectada y explicar el conflicto antes de ejecutar una acción irreversible.
