---
name: council
description: Convoca un consejo de tres modelos de distintos proveedores (Opus, Gemini Neon y un tercero que nombra el usuario) para revisar o dar feedback. Usala cuando el usuario diga "council".
---

<!-- Origen: tstack/skills/council (MIT, Theo Browne). Ver NOTICE.md.
     Cambios: miembros fijos Opus + Gemini Argon, tercer miembro elegido por el
     usuario al invocarlo; Gemini vía antigravity. -->

# council

Antes de convocar, resolvé los comentarios pendientes del PR, arreglá los
problemas conocidos y corré los checks que correspondan. El consejo revisa la
implementación actualizada: no dejes arreglos conocidos para después de las
revisiones. Si el usuario quiere descartar la implementación y explorar ideas
nuevas, no arregles código que se va a tirar.

## Miembros

Tres delegados de tres proveedores distintos, todos con razonamiento alto:

1. `claudeAgent` / `claude-opus-5-5`, effort `high`
2. `antigravity` / `gemini-4-neon`, `thinking_level: high`
3. El modelo que el usuario nombra al invocarlo (por ejemplo,
   "council con GPT Sol"), con su nivel de razonamiento alto.

Si el usuario no nombra el tercer miembro, preguntale cuál antes de lanzar
cualquier delegado. No elijas uno por tu cuenta ni arranques con dos.

- Gemini va siempre por `antigravity` (cuota del plan), nunca por `opencode`.
- Si el usuario nombra otros miembros, usá esos.
- Si un miembro no está disponible, reportalo. No lo sustituyas por otro.

## Lanzar

En T3 Code, llamá a `orchestrator_capabilities` para resolver los modelos y
después a `delegate_task`, un delegado por modelo, en paralelo. Fuera de T3
Code no hay ruta a Gemini ni al tercer proveedor: reportá el bloqueo en vez de
correr un consejo incompleto.

Pasale a cada delegado el pedido y el contexto relevante (rutas y alcance del
`git diff`, no archivos pegados). Para revisión o feedback, su trabajo es de
solo lectura. Juntá las respuestas y resumí los hallazgos útiles, los
desacuerdos y los próximos pasos recomendados.

No esperes sin hacer nada. Cuando llega un resultado, contrastá sus hallazgos
con el código en ese momento y decidí qué arreglar mientras los demás siguen
corriendo. No edites archivos mientras un delegado todavía revisa el mismo
checkout. Si el usuario marca un delegado como no bloqueante, no lo esperes:
un resultado tardío cuenta como feedback y su score no se registra.

## Rondas y score

En una revisión de código, pedile a cada delegado un score sobre 10. Cada
pasada completa de revisión es una ronda. Una revisión nueva después de los
arreglos arranca otra ronda.

Si estás de acuerdo con sus recomendaciones, hacé los cambios y pedí una
revisión nueva. Seguí así hasta que todos los delegados estén conformes.

## Reporte

Si el trabajo termina en un PR, poné los resultados en la descripción, antes de
la línea de modelo y harness del final:

```markdown
## Council review

Rounds: 2

| Delegate | Round 1 | Round 2 |
| --- | --- | --- |
| Claude Opus | 7/10 | 9/10 |
| Gemini Neon | 8/10 | 10/10 |
| GPT Sol | 7/10 | 9/10 |
```

Si un delegado no da score, escribí `no score`. No lo inventes. Si el PR está
abierto, editá la descripción; no publiques un comentario. Si no hay PR, poné
los mismos resultados solo en la respuesta final.

## Alcance

No dejes que las revisiones repetidas agranden el alcance. Tu trabajo es pelear
para mantenerlo chico.
