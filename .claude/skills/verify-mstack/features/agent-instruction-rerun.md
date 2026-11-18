# Regenerar AGENTS.md sin pisar `## Agent skills`

Después de que `/setup-matt-pocock-skills` agrega su sección `## Agent skills`,
el dev vuelve a correr `agent-instruction` (por ejemplo, porque cambió la KB).
La sección de Matt queda textual, las secciones propias de `agent-instruction`
se actualizan y `CLAUDE.md` sigue siendo solo `@AGENTS.md`.

## Sub-features

- `rerun-preserve` deja `## Agent skills` idéntica, byte a byte (salvo los finales de línea).
- `rerun-preserve-foreign` conserva cualquier otra sección que no sea de `agent-instruction`.
- `rerun-claude-md` deja `CLAUDE.md` en `@AGENTS.md` y no vuelve a copiar el contenido.

## How to get to it (user POV)

- En la sesión del proyecto, después del setup de Matt, el dev pide "regenerá AGENTS.md" o "actualizá las instrucciones para los agentes".

## Driving it with bash + gh + el usuario

Preconditions:

- Pasos de [la cadena de fundación](./foundation-chain.md) hasta **Setup de Matt** incluido, con `$OUT/agent-skills.before.md` guardado.

- **Sección ajena.** Agregá al final de `$TEST_REPO/AGENTS.md` una sección que no sea de nadie: `printf '\n## Notas del dev\n\nNo tocar.\n' >> "$TEST_REPO/AGENTS.md"`. Sirve para probar `rerun-preserve-foreign`.
- **Segunda corrida.** En la sesión del repo de prueba, el usuario pide "regenerá AGENTS.md" y `agent-instruction` termina.
- **Verificar la sección de Matt.** Corré `bash "<mstack>/.claude/skills/verify-mstack/scripts/check-e2e.sh" check "$TEST_REPO" "$OUT/agent-skills.before.md"`. Dice `PASS '## Agent skills' presente e idéntica al snapshot`.
- **Verificar la sección ajena.** Corré `grep -A2 '^## Notas del dev' "$TEST_REPO/AGENTS.md" | tee "$OUT/foreign-section.txt"`. Muestra `No tocar.`.
- **Prueba.** `$OUT/e2e.txt` (del paso Verificar de la cadena) y `$OUT/foreign-section.txt`.

## Gotchas

- `check-e2e check` exige el snapshot. Tomalo después de `/setup-matt-pocock-skills` y antes de la segunda corrida: si lo tomás después, compara la sección consigo misma y no prueba nada.
- Si `agent-instruction` pregunta si sobrescribe el archivo, la respuesta que prueba el comportamiento pedido es la que conserva las secciones. Si solo ofrece sobrescribirlo entero, es un bug.
