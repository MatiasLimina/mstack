# Mapa de verificación de mstack

Esta carpeta es la fuente mantenida para verificar lo que un usuario de mstack
ve y usa. Antes de verificar, leé este índice y después el feature que
corresponda como receta.

## Precondiciones base

- Checkout de mstack con `bash .claude/skills/verify-mstack/scripts/doctor.sh` sin ningún `MAL`.
- `RUN_ID` y `OUT=.verify-artifacts/$RUN_ID` creados como dice `SKILL.md` → Launch.
- Para los features de punta a punta: `gh` autenticado contra la cuenta del usuario, el usuario presente (la cadena hace preguntas y `/setup-matt-pocock-skills` solo lo invoca él) y su OK explícito para tocar `~/.claude/skills/`.
- El único repo de GitHub que se toca es el sandbox `MatiasLimina/Verify-mstack` (`D:/APruebas/Verify-mstack`). Nunca crees issues ni pushees a otro, mstack incluido.

## Convenciones

- Los scripts son bash; corrélos con la herramienta Bash y no los pases a PowerShell.
- Cada comando es literal. No cambies nombres entre comillas ni flags.
- Los pasos que dicen "el usuario corre" se los pedís al usuario con el comando exacto y esperás. Un agente no puede invocar `/setup-matt-pocock-skills`.

## Prueba y reporte de lo salteado

- La salida de un script va completa a `$OUT`, con su exit code.
- El estado de GitHub se prueba con `gh` y se guarda como JSON en `$OUT`.
- Reportá cada verificación por su nombre (el texto después de PASS/FAIL).
- Si no podés llegar a un paso (falta de scope, el usuario no está), reportalo como no verificado, con el comando que intentaste y la precondición que faltó. No lo des por verificado por otro camino.

## Contrato de cada feature

Cada archivo arranca con un H1 y un párrafo que dice qué ve el usuario. Después
vienen exactamente cuatro H2, en este orden: `Sub-features`, `How to get to it
(user POV)`, `Driving it with <harness>` (arranca con `Preconditions:`) y
`Gotchas`.

## Features

- [Chequeos estáticos](./static-checks.md): fundación sin OpenSpec, `name:` igual a la carpeta, derivadas con Origen y NOTICE, y el selftest que inyecta cada falla.
- [Instalar las skills desde el repo](./install-from-repo.md): lleva `skills/` a `~/.claude/skills/` con backup y restore, y es la precondición de la corrida de punta a punta.
- [Cadena de fundación de punta a punta](./foundation-chain.md): desde un repo vacío hasta KB, glosario, ADRs, el issue de roadmap y AGENTS.md, con todas las verificaciones de #10.
- [Regenerar AGENTS.md sin pisar `## Agent skills`](./agent-instruction-rerun.md): la segunda corrida de `agent-instruction` después de `/setup-matt-pocock-skills`.
