# Cadena de fundación de punta a punta

El dev arranca un proyecto grande y vacío con un remote en GitHub y corre la
fundación paso a paso. Cada skill le dice cuál es el próximo comando. Al
terminar, el proyecto tiene una KB de producto, un glosario y ADRs en el
formato de Matt, un único issue de roadmap y un `AGENTS.md` que
`/setup-matt-pocock-skills` puede completar. No aparece nada de OpenSpec ni
ningún archivo de estado.

## Sub-features

- `chain-discovery` (opcional): `discovery-research` deja `discovery/discovery.md`.
- `chain-kb`: `kb-creator` deja los 9 canónicos de `knowledge-base/` (01-08 y 10, sin 09), `GLOSSARY.md` y `docs/adr/NNNN-slug.md`.
- `chain-roadmap`: `roadmap-generator` publica exactamente un issue, con task list y niveles LOW/MEDIUM/HIGH/CRITICAL, y no crea issues hijos.
- `chain-agents`: `agent-instruction` escribe `AGENTS.md` como fuente y un `CLAUDE.md` que es solo `@AGENTS.md`.
- `chain-next-step`: cada skill termina diciendo el próximo comando exacto.
- `chain-no-openspec`: no aparece `openspec/` ni ningún `*-orchestrator-state.json`.

## How to get to it (user POV)

- En una sesión nueva de Claude Code abierta en el proyecto vacío, el dev pide "investiguemos el producto" (`discovery-research`) o "armá la KB" (`kb-creator`) y sigue el próximo comando que le da cada skill.
- Orden: `discovery-research` (opcional) → `kb-creator` → `roadmap-generator` → `agent-instruction` → `/setup-matt-pocock-skills` → `agent-instruction` otra vez.

## Driving it with bash + gh + el usuario

Preconditions:

- [Instalar las skills desde el repo](./install-from-repo.md) hecho, con `install-diff.txt` todo `igual`.
- `doctor.sh "$TEST_REPO"` sin `MAL`.
- El usuario está presente para responder las preguntas de la cadena, o le pidió al agente de la sesión de prueba que conteste con el fixture.

- **Resetear el sandbox.** Corré `TEST_REPO="D:/APruebas/Verify-mstack"; bash .claude/skills/verify-mstack/scripts/reset-sandbox.sh | tee "$OUT/reset.txt"`. Termina con `SANDBOX LIMPIO` (`issues=0 archivos=0`). Después, `bash .claude/skills/verify-mstack/scripts/doctor.sh "$TEST_REPO"` muestra `ok sandbox D:/APruebas/Verify-mstack -> github.com/MatiasLimina/Verify-mstack`.
- **Abrir la sesión.** Pedile al usuario que abra una sesión nueva de Claude Code (o un thread de T3 Code) con `$TEST_REPO` como directorio de trabajo. Con `ls ~/.claude/skills`, esa sesión ve las skills recién instaladas.
- **Correr la cadena.** El usuario pega en esa sesión el "Pedido inicial" de [fixtures/peluquerias.md](../fixtures/peluquerias.md), contesta cada pregunta con ese archivo y sigue cada próximo comando hasta terminar `agent-instruction`. Anotá en `$OUT/chain-log.md` el próximo comando que mostró cada skill, que tiene que nombrar la siguiente de la cadena, y cada pregunta que el fixture no cubría.
- **Setup de Matt.** El usuario corre `/mattpocock-skills:setup-matt-pocock-skills` con GitHub como tracker. Después corré `bash "<mstack>/.claude/skills/verify-mstack/scripts/check-e2e.sh" snapshot "$TEST_REPO" "$OUT/agent-skills.before.md"`, que dice `snapshot guardado`.
- **Segunda corrida.** Sigue en [Regenerar AGENTS.md](./agent-instruction-rerun.md).
- **Verificar.** Corré `bash "<mstack>/.claude/skills/verify-mstack/scripts/check-e2e.sh" check "$TEST_REPO" "$OUT/agent-skills.before.md" 2>&1 | tee "$OUT/e2e.txt"; echo "exit=${PIPESTATUS[0]}" | tee -a "$OUT/e2e.txt"`. Las siete verificaciones dicen `PASS`: los 9 canónicos sin 09, GLOSSARY con formato de Matt, docs/adr con formato de Matt, un solo issue de roadmap, AGENTS.md + CLAUDE.md, `## Agent skills` idéntica al snapshot, y nada de openspec ni archivos de estado.
- **Prueba.** Corré `(cd "$TEST_REPO" && find . -path ./.git -prune -o -print | sort) > "$OUT/tree.txt"; (cd "$TEST_REPO" && gh issue list --state all --json number,title,body) > "$OUT/issues.json"; cp "$TEST_REPO/AGENTS.md" "$TEST_REPO/CLAUDE.md" "$OUT/"`.
- **Cleanup.** Corré `bash .claude/skills/verify-mstack/scripts/reset-sandbox.sh` (termina con `SANDBOX LIMPIO`) y después el paso **Restaurar** de install-from-repo. Confirmá que `$OUT/e2e.txt`, `$OUT/issues.json` y `$OUT/tree.txt` siguen existiendo: después del reset, esa es la única copia de lo que produjo la cadena.

## Gotchas

- Si `check-e2e` da un resultado sospechoso, corré `bash .claude/skills/verify-mstack/scripts/selftest-e2e.sh "$OUT"` antes de culpar a la cadena. Ese script prueba cada verificación contra una salida armada a mano.
- `check-e2e.sh` revisa la forma de los archivos, no la calidad del contenido. Leé `GLOSSARY.md` y un ADR en `$OUT` antes de dar la prueba por buena: un glosario con términos genéricos de programación no cumple el formato de Matt aunque pase el chequeo.
- "Exactamente un issue" incluye los cerrados (`--state all`). Si la cadena creó y cerró un issue de más, igual falla, y está bien que falle.
- Si `roadmap-generator` pide confirmar el repo destino, la respuesta correcta es `MatiasLimina/Verify-mstack`. Si propone otro repo, es un bug.
- Sin el reset previo, la verificación de "un solo issue" falla por los issues de la corrida anterior, y está bien que falle. No la saltees: reseteá.
- `/setup-matt-pocock-skills` puede crear labels en el sandbox. El reset no las borra, y no afectan ninguna verificación.
- Hacé el reset con la sesión de prueba cerrada, porque `git clean -fdx` borra lo que la sesión esté escribiendo.
- `<mstack>` es la ruta del checkout de mstack (`git rev-parse --show-toplevel` desde la sesión que verifica), no la del repo de prueba.
