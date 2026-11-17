---
name: file-pr
description: Abre un pull request conciso. Usala cuando el usuario pida abrir, crear o subir un PR.
---

<!-- Origen: tstack/skills/file-pr (MIT, Theo Browne). Ver NOTICE.md.
     Cambios: traducida. -->

# file-pr

Antes de abrirlo, fijate si ya existe un PR para esta rama. Revisá el diff
local contra la rama base (normalmente `origin/main`) y confirmá que el
contenido coincide con el objetivo.

El título del PR suele terminar siendo el mensaje del commit, así que seguí
las convenciones del repo. Mirá PRs mergeados recientes y el historial de Git.
Preferí un título corto y legible que explique por qué importa el cambio:

MAL

> ❌ perf(server): negociar permessage-deflate en el websocket

BIEN

> ✅ perf(server): frames del websocket 70%+ más chicos con gzip

Arrancá la descripción con una explicación simple del problema, basada en el
pedido original del usuario, y después contá brevemente la solución. No
arranques con un inventario de la implementación:

MAL

> ❌ Saqué el arrastre implícito de workspace de todos los puntos de entrada de
> "nuevo thread" (cmd+n / cmd+shift+o, botones del sidebar v1/v2, command
> palette). Borré buildContextualThreadOptions y startNewThreadInProjectFromContext.

BIEN

> ✅ Mi default de "nuevo worktree" se ignoraba al crear threads sobre worktrees
> existentes. Nada intuitivo. Ahora tus preferencias se aplican siempre.

Cerrá la descripción con el nombre público del modelo y el harness que hicieron
los cambios, por ejemplo `Created with <modelo> in <harness>.` Incluí los
modelos de subagentes que escribieron parte del cambio. Usá el nombre que
informa el harness. Si no sabés qué modelo sos, nombrá solo el harness; no
adivines. Si el harness pide su propia línea de atribución, usá esa.

Antes de enviarlo, revisá título, descripción, citas y adjuntos en busca de
secretos y datos privados.

Abrí un PR real, no un draft, así revisa Copilot si el repo lo tiene. Si `gh pr create`
falla porque se agotó el rate limit de GraphQL, abrilo por REST con
`gh api repos/<owner>/<repo>/pulls -f title=... -f head=... -f base=... -F body=@<archivo>`.
Si el usuario también pidió vigilarlo, seguí con la skill `babysit-pr`.

No dejes un comentario de seguimiento en el PR salvo que sirva al pedido del
usuario. Si hace falta, usá la skill `leaving-pr-comments`.
