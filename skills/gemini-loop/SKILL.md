---
name: gemini-loop
description: Revisa un cambio con un revisor Gemini en loop hasta que los dos agentes estén de acuerdo (Neon en cambios normales, Carbon en los arriesgados). Usala cuando el usuario diga "gemini loop", o cuando full-send / full-stop pidan el paso de feedback.
---

<!-- Origen: tstack/skills/sol-loop (MIT, Theo Browne). Ver NOTICE.md.
     Cambios: revisor Gemini vía antigravity con cadena de fallback, en vez de GPT Sol;
     dos cadenas según riesgo (Carbon revisa los cambios arriesgados). -->

# gemini-loop

Workflow para hacer un cambio más correcto antes (o a veces después) de abrir
el PR: un revisor Gemini lo revisa en loop.

Hacé los cambios mínimos para conformar al revisor. Cuidado con el scope creep
y no tengas miedo de discutirle.

## Revisor

Hay dos cadenas. Cuál usás depende de si el cambio es arriesgado (ver
Presupuesto), y lo decidís una sola vez, en el paso 1.

Cadena normal, en orden:

1. `antigravity` / `gemini-4-neon`, `thought_level: medium`
2. `antigravity` / `gemini-4-argon`, `thought_level: medium` (fallback)

Cadena arriesgada, en orden, todos con `thought_level: high`:

1. `antigravity` / `gemini-4-carbon`
2. `antigravity` / `gemini-4-neon` (fallback)
3. `antigravity` / `gemini-4-argon` (fallback)

Carbon es el más fuerte en código complejo, pero gasta más cuota y tarda más.
Por eso revisa solo lo arriesgado.

Overrides: si el `CLAUDE.md` / `AGENTS.md` del usuario define
`gemini-loop — cadena: <modelos>`, esa reemplaza la cadena normal. Si define
`gemini-loop — cadena arriesgada: <modelos>`, esa reemplaza la arriesgada. Cada
override toca solo su cadena. Una línea vieja que diga solo "otra cadena" para
`gemini-loop`, sin aclarar cuál, cuenta como la normal.

Reglas del fallback (valen para las dos cadenas):

- Pasás al siguiente modelo **solo** si el actual no está disponible, da
  error, o no responde. Nunca porque devolvió `CHANGES`: un veredicto que no
  te gusta no es una falla del revisor.
- Una vez que cambiaste de modelo, quedate con ese el resto del loop. No
  mezcles revisores entre rondas.
- Gemini va siempre por `antigravity` (cuota del plan), nunca por `opencode`.
- Si ningún modelo de la cadena corre, reportá el bloqueo. No sustituyas por
  un modelo fuera de la cadena.

## Presupuesto

- Default: 3 rondas en total. La ronda 1 es completa. Las siguientes revisan
  solo el código cambiado y los hallazgos abiertos.
- Cambios arriesgados: seguridad, permisos, auth, pérdida de datos o
  estado/concurrencia. Ahí usás la cadena arriesgada (Carbon primero, todo en
  `thought_level: high`) y el tope pasa a 5 rondas, mientras siga abierto un
  blocker o should con evidencia. También si el usuario lo pide, por ejemplo
  "revisalo con Carbon". Decidí si es arriesgado en el paso 1 y anotalo en el
  brief con la cadena elegida. No lo cambies a mitad del loop.
- Cortá antes si una ronda devuelve solo nits. Los nits rechazados y los
  arreglos de solo comentarios, docs o formato no abren una ronda nueva.

Siempre:

- Un solo revisor. El revisor no puede iniciar subagentes ni otros revisores.
- Llevá un ledger: id, severidad, resultado, uso si se informa. Nunca lo
  inventes.

## 1. Alcance

Corré `git status --short`. No hagas stash, no descartes ni incluyas cambios
ajenos. Limitá la revisión a los paths del cambio si se separan limpio. Si no,
frená y preguntá.

Encontrá la base después de `git fetch origin`:

- PR: `gh pr view <n> --json baseRefName,headRefOid`. Hacé checkout de la rama
  solo si está limpia. Confirmá que `HEAD` es el head del PR, o que está
  adelante solo por este cambio. Base: `git merge-base HEAD origin/<baseRefName>`.
- Local: `git merge-base HEAD origin/<rama-default>`. Sin remoto: una base que
  nombre el usuario, o `HEAD` solo para cambios sin commitear.

El cambio es de la base al working tree en esos paths, con los archivos sin
trackear. Usá un mismo comando de diff en todas las rondas. Escribí la
intención y lo que queda fuera de alcance en 1-2 oraciones. Corré los checks
que cubren el cambio. No mandes código que este cambio rompe. Anotá en el
brief los checks que faltan o que ya fallaban antes.

## 2. Lanzar el revisor

En T3 Code, llamá a `orchestrator_capabilities` una vez y confirmá que el
primer modelo de la cadena elegida existe (si no existe, eso cuenta como falla
y aplica el fallback). Usá `delegate_task` en cada ronda
(`role: "review"`, `mode: "async"`). Guardá el `taskId`. Un `clientRequestId`
nuevo por ronda. `childThreadId` es almacenamiento, no el destino siguiente.
No uses `t3_thread_send`, `create_threads` ni `t3_thread_launch` para revisar.

Fuera de T3 Code no hay ruta a Gemini: reportá el bloqueo y sugerí el agente
`advisor` como alternativa. No lo corras sin que el usuario acepte.

No edites archivos del alcance mientras el revisor trabaja. Esperá el aviso.
No hagas polling ni lances un segundo revisor. Timeout, error o falta de
respuesta no es aprobación: aplicá las reglas del fallback, cancelá, verificá
que paró y reiniciá con el ledger.

Brief de la ronda 1 (los hijos de T3 no tienen historial):

```
Review only. Do not edit, commit, push, comment on PRs, or start subagents.
Repo: <abs path> Base: <sha> Intent: <intent> Out of scope: <scope> Checks: <results>
Risk: <normal | risky: reason>
See: git diff <base> [-- <paths>]; git status --short (read untracked).
Read surrounding code. Find bugs, broken callers, mismatch with intent.
Skip style unless it hides a bug. Hold to the smallest change. Flag code,
tests, or guards the intent does not need. Other paths, rare cases, small
perf, extra compat: nits.
blocker = intended case wrong. should = real bug callers will hit, in intent. nit = rest.
Reply:
VERDICT: APPROVE or CHANGES
S1 [blocker|should|nit] <file>:<line> <claim>. Fix: <suggestion> (stable ids)
```

## 3. Responder los hallazgos

Verificá vos cada hallazgo y su severidad. Otro path, un caso raro o un costo
chico es un nit, venga con la etiqueta que venga.

- De acuerdo: el arreglo más chico. Preferí borrar o acotar antes que agregar
  un lock, cache, helper u opción. Arreglá el caso que pasó. Agregá un test
  enfocado que falle sin el arreglo, si la intención lo necesita.
- En desacuerdo: decí por qué, con evidencia (archivo:línea, test, output).
- Fuera de alcance o nit: rechazalo en una línea. Listalo como pendiente.

Actualizá el ledger. Volvé a correr los checks y `git diff --shortstat <base>`.
Si la revisión agrandó el diff, recortá primero. No aceptes cosas solo para
terminar el loop.

## 4. Ronda siguiente

Arrancá una solo si queda presupuesto y hay un blocker o should abierto, cambió
código de comportamiento, o la aprobación no cubre el diff de comportamiento
actual. Usá un `delegate_task` nuevo. Mandá el brief de la ronda 1, el ledger
(`fixed:` / `disagree:` / `declined:` + evidencia), el mismo diff base y el
cambio desde la ronda anterior. Pedile al revisor: solo ids abiertos y código
cambiado. Que marque cada id viejo como `resolved` o `still open: <motivo>`.

## 5. Cortar y entregar

De acuerdo: `APPROVE` sobre el diff de comportamiento actual, sin blocker ni
should abiertos, y sin dudas propias. Trabado: un ítem sigue en disputa después
de dos respuestas, o se acabó el presupuesto. Mostrá las dos posturas en 2-3
líneas cada una. Decide el usuario. Terminar el presupuesto no es aprobación.

No pushees durante el loop. Pusheá después del acuerdo solo si el usuario pidió
pushear, entregar o actualizar el PR. Si pusheás a un PR, agregá arriba de la
línea de modelo:

`Reviewed with gemini-loop: <N> rounds with <model>. Verdict: approved`.

Si hubo fallback, nombrá ambos modelos y en qué ronda cambió.

Reporte: cadena usada (normal o arriesgada) y por qué, rondas, modelo(s), qué cambió por la revisión, tamaño del diff
antes/después, hallazgos arreglados y rechazados con motivo, uso si se informa
(si no, decilo), si pusheaste o no.
