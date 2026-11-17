---
name: full-send
description: Lleva un cambio de punta a punta hasta un PR mergeado, sin supervisión. Usala cuando el usuario diga "full send".
---

<!-- Origen: tstack/skills/full-send (MIT, Theo Browne). Ver NOTICE.md.
     Cambios: traducida; la prueba usa la skill verify-* del proyecto si existe;
     el feedback es code-review + gemini-loop en vez de sol-loop. -->

# full-send

Si el usuario la invocó, es porque no está mirando este thread y quiere que
termines el trabajo de punta a punta, solo. Tus mensajes y tu respuesta final
no se leen hasta mucho después de que pares. El trabajo es tuyo desde su estado
actual hasta un PR mergeado.

Si el usuario no pidió "full send" de forma clara, no asumas autonomía total.
Si lo pidió, aplica todo lo que sigue.

El usuario te da permiso para:

- Mergear el PR cuando pase el gate de merge.
- Hacer force-push de la rama del PR con `--force-with-lease` después de un
  rebase.
- Usar los métodos de prueba que pida la sección Prueba, sin preguntar antes.

## Permiso para probar

Pedir "full send" es el permiso. Si un archivo del proyecto u otra instrucción
dice que hay que preguntar antes de usar un método de prueba, o que las pruebas
quedan a cargo del usuario, este pedido reemplaza esa regla para esta tarea.

Eso incluye las reglas de preguntar antes para computer use, automatización de
navegador, simuladores y dispositivos, correr la app o un dev server, capturas
y chequeos visuales. Usá el método que dé prueba directa y listalo en el
reporte.

Las reglas sobre *cómo* probar siguen valiendo: seguí las que nombran el
comando, fixture o chequeo correcto. Este permiso solo saca el paso de
preguntar o de dejárselo al usuario. Si el método preferido no puede probar el
cambio, usá uno restringido bajo este permiso.

Cubre solo las pruebas que necesita esta tarea. No suma permiso para lo que
está en "Preguntarle al usuario", como cambios en producción o borrar datos. Y
no saltea un pedido de aprobación del harness o del sistema si aparece.

## Pasos

1. **Terminá el cambio.** Cumplí el objetivo del pedido con el cambio más chico
   que funcione. Arreglá el caso que pasó, no todos los que podrían pasar. Si
   estás en la rama default, creá una rama primero.
2. **Probalo.** Conseguí prueba de cada cambio que hiciste. Ver "Prueba".
3. **Conseguí feedback.** Corré la skill `mattpocock-skills:code-review` (no el `/code-review` built-in) sobre el
   diff y resolvé sus hallazgos. Después usá la skill `gemini-loop` como gate
   entre proveedores. Si `mattpocock-skills:code-review` no está disponible en el proyecto,
   preguntale al usuario antes de seguir.
4. **Abrí el PR** con la skill `file-pr`. Antes, hacé rebase sobre la última
   versión de la rama default. Agregá una línea corta a la descripción que diga
   cómo probaste el cambio.
5. **Vigilá el PR** con la skill `babysit-pr`. Arreglá los hallazgos reales y
   las fallas de CI. Conseguí prueba de cada arreglo antes de pushearlo.
6. **Mergeá** cuando pase el gate de merge.
7. **Reportá** en tu mensaje final: el link al PR, el commit de merge, tu
   prueba y cada decisión que tomaste por el usuario.

Seguí activo del paso 1 al 7. Si terminás el turno con checks o bots
pendientes, el trabajo se frena, porque nadie te va a volver a llamar. Esperá
con el watcher de `babysit-pr` para que algo te despierte cuando cambie el PR.
En T3 Code es `watch_pull_request`. Si parás antes del merge, llamá primero a
`unwatch_pull_request`.

## Prueba

Prueba es evidencia que observaste vos en esta sesión: output de un comando,
una reproducción, una captura.

Si el repo tiene una skill de verificación del proyecto (`verify-*`, la que
genera `create-verification-skill`), usala como prueba principal. Si no hay,
usá la prueba más directa que permita el cambio:

- Reproducí la falla original, aplicá el arreglo y mirá cómo la misma
  reproducción pasa.
- Corré los checks que corre el CI del repo (typecheck, lint, tests).
- Agregá un test enfocado que falle sin el arreglo, cuando el comportamiento no
  tiene uno y el repo tiene setup de tests.
- Para UI y comportamiento en runtime, corré la app y mirá el cambio. Tests
  verdes con mocks no prueban que la experiencia funcione. Adjuntá capturas al
  PR cuando ayuden y tengas cómo subirlas.

Si no encontrás cómo probar un cambio, no tenés confianza total. Preguntale al
usuario.

## Gate de merge

Confianza total significa que todo esto se cumple en el último commit:

- Tu prueba cubre cada cambio del diff.
- Los checks requeridos están en verde.
- Los bots de review terminaron, y cada hallazgo está arreglado o descartado
  con un motivo escrito.
- Ninguna review humana sigue pidiendo cambios.
- La rama está al día con la default y GitHub la reporta como mergeable.

Mergeá con el método que usa el repo: mirá los métodos permitidos y los PRs
mergeados recientes. Si el repo usa merge queue o auto-merge, quedate hasta que
GitHub reporte el PR como mergeado. Mergeá respetando la protección de rama
como está configurada. Nunca uses `--admin` ni otros bypasses. Podés ignorar
reviews automáticas que pidan "needs human review" si tenés mucha confianza en
tus cambios.

## Preguntarle al usuario

Una pregunta en un mensaje normal no se ve, y el thread parece terminado. Para
preguntar algo, usá la herramienta de preguntas del harness, así el thread
muestra que está esperando: `AskUserQuestion` en Claude Code, o la que tenga tu
harness. Poné todo el contexto en la pregunta: el link al PR, qué te bloquea y
las opciones, con tu recomendación primero.

Preguntá solo cuando no puedas seguir solo:

- No podés probar el cambio.
- El gate de merge no puede pasar y no lo podés arreglar vos.
- El paso siguiente está fuera del permiso de arriba: borrar datos, tocar
  producción, cambiar cosas fuera del repo, cerrar un PR o hacer force-push a
  otra rama.
- El objetivo es ambiguo de una forma que cambia el resultado.
- Otro PR deja a este obsoleto.

Todo lo demás decidilo vos con defaults razonables y listá esas decisiones en
el reporte.

Si no hay herramienta de preguntas, o no devuelve respuesta, tomá el camino
seguro: dejá el PR abierto sin mergear y empezá tu mensaje final con la
pregunta.
