---
name: babysit-pr
description: Vigila un pull request durante la review y el CI. Usala cuando el usuario pida monitorear, vigilar o "babysit" un PR.
---

<!-- Origen: tstack/skills/babysit-pr (MIT, Theo Browne). Ver NOTICE.md.
     Cambios: traducida; pr-wait corre en Windows. -->

# babysit-pr

Muchos repos tienen bots de review con IA. Ayudan, aunque no siempre tienen
razón.

## Esperar

Nunca escribas tu propio watcher, loop de polling ni loop con `sleep`. Un solo
watcher por PR: `watch_pull_request` en T3 Code, `pr-wait` en el resto. Nunca
los dos sobre el mismo PR. Todos los watchers de una cuenta de GitHub comparten
el mismo rate limit.

### En T3 Code: `watch_pull_request`

Primero resolvé los checks y comentarios que ya existen. Después llamá a
`watch_pull_request` y terminá el turno. T3 Code te despierta cuando falla un
check, pasan los checks requeridos, alguien comenta o revisa, o la rama tiene
conflictos.

- **Solo vigila el PR el thread que es dueño.** Si sos una tarea delegada (un
  revisor, una ronda de `gemini-loop`, cualquier hijo de `delegate_task`),
  nunca llames a `watch_pull_request`. El PR es del padre. No vigiles PRs en
  los que no estás trabajando.
- **Un aviso es una noticia, no una decisión de merge.** Chequeá vos el gate de
  merge.
- **Dejá de vigilar al entregar.** Un thread que vigila queda en Working y fuera
  del inbox del usuario. Cuando parás (listo, trabado o con una pregunta),
  llamá antes a `unwatch_pull_request`. Un merge o cierre corta la vigilancia
  solo.
- **"Stopped watching, could not read it"** suele ser el rate limit de GitHub.
  Corré `gh api rate_limit --jq .resources.graphql` antes de volver a vigilar.
  Si `remaining` está cerca de 0, esperá al `reset` con un único comando en
  background y recién ahí volvé a vigilar. Nunca en un loop apretado.

### En el resto: `pr-wait`

Esperá con `scripts/pr-wait` de la carpeta de esta skill (usá su ruta
absoluta). Es Python 3 y funciona en Windows, macOS y Linux; en Windows corrélo
como `python <ruta>/pr-wait`.

```bash
pr-wait <pr> [--repo owner/name] [--until ready|green|any-change]
```

Imprime una línea por cada evento real. Sale con 0 cuando se cumple el
`--until` o el PR se mergea, con 1 cuando te necesita (falló un check
requerido, conflictos, threads sin resolver, PR cerrado), y con 2 si la
entrada es inválida u otro `pr-wait` ya vigila ese PR.

- `ready` (default): checks requeridos en verde, Greptile o Macroscope
  revisaron el head, y no hay threads sin resolver. Usalo para vigilar.
- `green`: solo checks requeridos. Usalo si el repo no tiene Greptile ni
  Macroscope.
- `any-change`: sale con el primer evento.

En Claude Code, corrélo con la herramienta Monitor (`timeout_ms: 3600000`), así
cada línea te despierta. Sin monitor, corrélo como un solo comando largo.
Termina solo.

Volvé a lanzarlo después de pushear, de resolver un exit 1 y de retomar.
Recuerda lo que ya reportó, así que no se pierde nada de lo que llegó en el
medio. Si dice que otro pid ya vigila el PR, no arranques un segundo. Matá el
viejo solo si sus eventos no te llegan.

Con cualquiera de los dos: si un evento no requiere acción, terminá el turno
sin mensaje. Nunca postees ni digas "sigo esperando".

## Rate limits de GitHub

`gh pr create`, `gh pr view` y `gh pr checks` usan GraphQL. Cuando GraphQL se
agota, el límite de REST es aparte y suele tener margen. Usá
`gh api repos/<owner>/<repo>/pulls/<n>` para leer un PR y
`gh api repos/<owner>/<repo>/commits/<sha>/check-runs` para los checks.

## Reviews

Actuá solo sobre checks y comentarios posteriores al último push. Verificá cada
hallazgo de un bot contra el código antes de cambiar nada. Arreglá los
hallazgos reales y las fallas de CI, distinguí fallas del repo de flakes de
infraestructura, y respondé con un motivo escrito al descartar falsos positivos.

Si el repo tiene `.macroscope/check-run-agents/*.md`, leé esas reglas antes de
responder un hallazgo de Macroscope. Sus hallazgos las citan.

CodeRabbit es consultivo. Tratá sus hallazgos como cualquier otro, pero nunca
lo esperes ni frenes un merge por él.

Si un bot deja feedback que creés que no vale la pena, respondé con un motivo
escrito y resolvé el comentario. Usá la skill `leaving-pr-comments` para todo
comentario que postees en nombre del usuario.

Las capturas y videos también ayudan, si tenés forma de subirlos.

Mantené el PR del tamaño que necesita el objetivo del usuario. Los loops de
review tienden a inflar el PR de a un arreglo barato por vez. Arreglá los bugs
reales del caso buscado. Rechazá el resto con un motivo escrito y listalo como
pendiente: tests innecesarios, guards para casos borde que no importan,
integración o compatibilidad extra, costos chicos de performance. Preferí el
arreglo que borra o acota código.

## Rama base y merge

Seguí los cambios en `main` y rebaseá cuando haga falta. `pr-wait` avisa cuando
commits nuevos de la base tocan archivos de este PR, y cuando el PR queda
BEHIND o DIRTY. `watch_pull_request` solo avisa conflictos, así que chequeá
BEHIND vos antes de decir que el PR está listo.
Si otro PR superpuesto vuelve obsoleto a este, dejá de vigilar, avisale al
usuario y preguntá antes de cerrarlo, salvo que el cierre esté autorizado.

Si no cambió nada, quedate callado en vez de postear comentarios de relleno.
Pará cuando `pr-wait` sale con 0, o en T3 Code cuando el gate de merge pasa
sobre el último head. Mergeá solo si el usuario lo pidió explícitamente; si no,
reportá que el PR está listo. Justo antes de mergear, corré `git fetch` y
revisá el PR otra vez. Nunca mergees si está BEHIND o DIRTY, o si commits de la
base que entraron después del último run verde tocan archivos del PR. Rebaseá,
pusheá y esperá el verde de nuevo.
