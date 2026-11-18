# Instalar las skills desde el repo

El dev copia `skills/` de mstack a `~/.claude/skills/`, como dice el README, y
desde ese momento las sesiones nuevas de Claude Code usan esa versión. Para la
corrida de punta a punta es obligatorio: si no, se prueban las skills viejas de
active-stack que ya estaban instaladas.

## Sub-features

- `install-backup` guarda las versiones instaladas de las skills que se van a pisar.
- `install-copy` copia las skills del repo y deja cada `SKILL.md` idéntico al del repo.
- `install-restore` deja `~/.claude/skills/` como estaba antes de la corrida.

## How to get to it (user POV)

- La sección Instalación del README (`Copy-Item -Recurse -Force "mstack\skills\*" ...` en PowerShell).
- El agente, como primer paso de la corrida de punta a punta, con el OK del usuario.

## Driving it with bash

Preconditions:

- El usuario autorizó tocar `~/.claude/skills/` en esta corrida. Es una inyección en dotfiles (governance HIGH): sin ese OK, no sigas.
- `RUN_ID` y `OUT` creados.

- **Backup.** Corré `BAK="$HOME/.claude/skills.bak-$RUN_ID"; mkdir -p "$BAK"; for d in skills/*/; do n=$(basename "$d"); [ -e "$HOME/.claude/skills/$n" ] && cp -r "$HOME/.claude/skills/$n" "$BAK/"; done; ls "$BAK" | tee "$OUT/install-backup.txt"`. Lista las skills que estaban instaladas y se van a pisar.
- **Copiar.** Corré `for d in skills/*/; do n=$(basename "$d"); rm -rf "$HOME/.claude/skills/$n"; cp -r "$d" "$HOME/.claude/skills/$n"; done`. Antes del `cp` se borra la carpeta, para que no quede ningún archivo viejo que el repo ya no tiene.
- **Confirmar.** Corré `for d in skills/*/; do n=$(basename "$d"); diff -rq "$d" "$HOME/.claude/skills/$n" >/dev/null && echo "igual $n" || echo "DISTINTA $n"; done | tee "$OUT/install-diff.txt"`. Todas las líneas dicen `igual`.
- **Restaurar (cleanup).** Corré `for d in skills/*/; do n=$(basename "$d"); rm -rf "$HOME/.claude/skills/$n"; [ -e "$BAK/$n" ] && cp -r "$BAK/$n" "$HOME/.claude/skills/$n"; done`. Después borrá `$BAK` solo si `diff -rq` contra el backup da vacío para cada skill restaurada.
- **Prueba.** `$OUT/install-backup.txt` y `$OUT/install-diff.txt`.

## Gotchas

- Las skills se cargan al iniciar la sesión. La cadena se corre en una sesión **nueva** abierta en el repo de prueba; la sesión que instaló sigue viendo las versiones viejas.
- No uses `.claude/skills/` del repo de prueba como atajo: si una skill con el mismo nombre está instalada a nivel usuario, gana la del usuario y terminás probando la versión vieja.
- Una skill que el repo borró sigue instalada después de copiar. Si el cambio elimina una skill, sacala a mano de `~/.claude/skills/` (con backup) para que la prueba sea fiel.
- Restaurá aunque la corrida falle a la mitad. Si no, el dev queda con skills a medio adaptar en todas sus sesiones.
