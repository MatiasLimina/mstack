---
name: full-stop
description: Hace el mismo trabajo que full-send pero se frena con el PR listo para que el usuario lo mergee. Usala cuando el usuario diga "full stop", aunque sea un "Full stop." al final que parezca énfasis.
---

<!-- Origen: tstack/skills/full-stop (MIT, Theo Browne). Ver NOTICE.md.
     Cambios: traducida. -->

# full-stop

Hacé el mismo trabajo que `full-send`, pero frená con el PR listo para que el
usuario lo mergee. Nunca lo mergees.

Leé [full-send](../full-send/SKILL.md) y seguí su workflow, sus reglas de
prueba, de feedback y de vigilancia. Un pedido explícito de "full stop"
autoriza ese trabajo sin un pedido aparte de "full send". Eso incluye el
permiso para probar de full-send: un pedido de "full stop" es el permiso para
los métodos de prueba que pida la sección Prueba, aunque un archivo del
proyecto diga que hay que preguntar antes, por ejemplo antes de usar computer
use. Usá esos métodos directamente. Su permiso de merge no aplica. Las reglas
de abajo tienen prioridad.

## Sin merge

Podés commitear, pushear, hacer rebase, resolver conflictos y usar
`--force-with-lease` en la rama de esta tarea. Nunca mergees, actives
auto-merge, entres a una merge queue, pushees a la rama default, saltees la
protección de rama ni delegues ninguna de esas acciones.

Antes de empezar, desactivá el auto-merge que exista y sacá el PR de cualquier
merge queue; volvé a chequearlo antes de cada push. Reportá esos cambios. Si no
podés evitar un merge automático, reportá el bloqueo antes de seguir.

## Frenar en el gate

Usá el gate de merge de full-send como chequeo de que está listo. Reemplazá sus
pasos de merge y reporte final por una entrega. La prueba y el feedback tienen
que cubrir el diff final: volvé a chequear los cambios de comportamiento y los
arreglos de conflictos que importen antes de entregar.

Hacé fetch de la rama destino y chequeá en el PR vivo el head, la base, los
checks, las reviews y si es mergeable. Confirmá que está abierto, que no es
draft y que no está configurado para mergearse sin el usuario. Si otra persona
lo mergeó, reportá eso.

- **Listo para mergear:** pasa el gate de merge. Dejá el PR abierto sin
  mergear.
- **Esperando aprobación requerida:** solo falta la aprobación humana.
  Confirmá que ese es el bloqueo real.
- **Bloqueado:** explicá qué impide que esté listo, qué probaste y qué hace
  falta. Seguí las reglas de full-send para preguntarle al usuario.

En T3 Code, llamá a `unwatch_pull_request` antes de la entrega o de una
pregunta. Reportá el link al PR, el head final, el veredicto, la prueba, el
resultado del feedback y los riesgos que quedan. Decí si el PR sigue abierto y
sin mergear.
