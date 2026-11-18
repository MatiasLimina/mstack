# Chequeos estáticos

Antes de mergear, el dev quiere saber en segundos, sin correr agentes, si el
repo rompió alguna regla de forma: una skill de fundación que vuelve a
mencionar OpenSpec, una skill cuyo `name:` no coincide con su carpeta (y por eso
no se invoca con su nombre) o una skill derivada sin crédito.

## Sub-features

- `static-foundation` falla si una skill de fundación presente menciona `openspec`, `/opsx`, `CHANGES.md` u `orchestrator-state`, y lista cada `archivo:línea`.
- `static-foundation-absent` no falla por una skill de fundación que todavía no está en el repo; la nombra como no revisada.
- `static-names` falla si el `name:` del frontmatter de una skill (de `skills/` o de `.claude/skills/`) no coincide con su carpeta, o si falta el frontmatter.
- `static-derived` falla si una skill con `<!-- Origen:` no figura en NOTICE, si una skill de fundación no tiene Origen o si NOTICE lista una skill que no existe o no tiene Origen.
- `static-selftest` prueba que cada uno de los chequeos anteriores falla ante la falla inyectada.

## How to get to it (user POV)

- El agente corre `check-static.sh` en el paso verify de cualquier ticket de mstack.
- El dev le pide al agente "verificá mstack" o "corré los chequeos estáticos".
- `selftest.sh` se corre al cambiar `check-static.sh`.

## Driving it with bash

Preconditions:

- `doctor.sh` sin `MAL`.
- `OUT` creado.

- **Chequeos sobre el repo.** Corré `bash .claude/skills/verify-mstack/scripts/check-static.sh 2>&1 | tee "$OUT/static.txt"; echo "exit=${PIPESTATUS[0]}" | tee -a "$OUT/static.txt"`. Hay tres líneas `PASS`/`FAIL` y `RESULTADO`. El exit es `0` solo si las tres pasan. Contrastalo con la tabla de resultados esperados de `SKILL.md`.
- **Falla inyectada.** Corré `bash .claude/skills/verify-mstack/scripts/selftest.sh "$OUT" 2>&1 | tee "$OUT/selftest.txt"`. Cada escenario imprime `ok <nombre>` y el final dice `SELFTEST: todos los escenarios ok`. En `$OUT/selftest-opsx.txt` aparece `FAIL fundación sin OpenSpec` con `skills/kb-creator/SKILL.md:<línea>: ... /opsx:propose`, y en `$OUT/selftest-name.txt` aparece `name: 'consejo' pero la carpeta es 'council'`.
- **Otra copia.** Para revisar una rama sin cambiarte, corré `git worktree add "$TMP_WT" <rama>` y después `bash .claude/skills/verify-mstack/scripts/check-static.sh "$TMP_WT"`. Al terminar, `git worktree remove "$TMP_WT"`.
- **Prueba.** `$OUT/static.txt` con exit `0` (o con los FAIL esperados para el estado del repo) y `$OUT/selftest.txt` con todos los escenarios `ok`.

## Gotchas

- Los chequeos leen el working tree, no `HEAD`. Un archivo sin commitear cuenta.
- Los archivos tienen CRLF (`core.autocrlf=true`). Los scripts sacan los `\r`; un chequeo nuevo tiene que hacer lo mismo o `name: x\r` no va a coincidir con `x`.
- NOTICE se parsea por viñetas que arrancan con `` - `skills/<nombre>` ``. Una entrada escrita de otra forma no cuenta como listada.
- `opsx-orchestrator` menciona OpenSpec a propósito. No es de fundación y queda fuera del chequeo 1. No la sumes a `FOUNDATION`.
- Entre #13 y #17, el FAIL de "fundación sin OpenSpec" es lo esperado. No lo tapes; listá las líneas en el reporte.
