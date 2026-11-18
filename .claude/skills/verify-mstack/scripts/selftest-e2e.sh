#!/usr/bin/env bash
# Verifica check-e2e.sh: arma en el sandbox a mano una salida "buena" de la
# fundación (KB, glosario, ADR, issue de roadmap, AGENTS.md), comprueba que
# check-e2e pasa, y después rompe una cosa por escenario y comprueba que falla
# con el mensaje correcto. Al final resetea el sandbox.
#
# Toca GitHub (crea, edita y borra issues), pero solo en MSTACK_VERIFY_REPO:
# arranca y termina con reset-sandbox.sh, que se niega a correr sobre otro repo.
#
# Uso:  bash selftest-e2e.sh [OUT_DIR]
# Env:  MSTACK_VERIFY_DIR, MSTACK_VERIFY_REPO (ver reset-sandbox.sh)
# Exit: 0 todos los escenarios se comportan como se espera, 1 si no, 2 si el sandbox no está.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
DIR="${MSTACK_VERIFY_DIR:-D:/APruebas/Verify-mstack}"
OUT="${1:-}"; [ -n "$OUT" ] && mkdir -p "$OUT" && OUT="$(cd "$OUT" && pwd)"  # absoluta: después hay cd al sandbox
PRISTINE="$(mktemp -d "${TMPDIR:-/tmp}/verify-mstack-e2e.XXXXXX")"
SNAP="$PRISTINE.snapshot.md"
failures=0

bash "$HERE/reset-sandbox.sh" >/dev/null || { echo "ERROR: no pude resetear el sandbox" >&2; exit 2; }
trap 'bash "$HERE/reset-sandbox.sh" >/dev/null; rm -rf "$PRISTINE" "$SNAP"' EXIT

# --- Salida buena, armada a mano ------------------------------------------
cd "$DIR" || exit 2
mkdir -p knowledge-base docs/adr
for f in 01_vision_y_objetivos 02_descripcion_general 03_actores_y_roles 04_modelo_de_datos \
         05_reglas_de_negocio 06_funcionalidades 07_flujos_principales 08_arquitectura_propuesta \
         10_preguntas_abiertas; do
  printf '# %s\n\nContenido de prueba de Turnera.\n' "$f" > "knowledge-base/$f.md"
done
{ printf '# Knowledge base\n\n'
  for f in knowledge-base/*.md; do printf -- '- [%s](%s)\n' "${f#knowledge-base/}" "${f#knowledge-base/}"; done
  printf -- '- Vocabulario: [GLOSSARY.md](../GLOSSARY.md)\n- Decisiones: [docs/adr/](../docs/adr/)\n'
} > knowledge-base/README.md.tmp && mv knowledge-base/README.md.tmp knowledge-base/README.md
cat > GLOSSARY.md <<'EOF'
# Turnera

Turnos para una red de peluquerías.

## Language

**Turno**:
Un bloque de agenda reservado para un cliente, un servicio y un peluquero.
_Avoid_: Cita, reserva

**Ausencia**:
Un turno al que el cliente no vino sin cancelar con 12 horas de anticipación.
_Avoid_: Falta, no-show
EOF
cat > docs/adr/0001-los-turnos-no-se-borran.md <<'EOF'
# Los turnos no se borran, se cancelan

Las ausencias se cuentan sobre el historial de turnos, así que un turno cancelado tiene que seguir existiendo.
EOF
cat > AGENTS.md <<'EOF'
# Turnera

## Stack

Web móvil, un solo dev.

## Reglas duras

- Un turno nunca se borra.

## Agent skills

### Issue tracker

GitHub Issues (`MatiasLimina/Verify-mstack`).
EOF
printf '@AGENTS.md\n' > CLAUDE.md
bash "$HERE/check-e2e.sh" snapshot "$DIR" "$SNAP" >/dev/null
cp -r "$DIR"/. "$PRISTINE"/ && rm -rf "$PRISTINE/.git"

ROADMAP='# Roadmap de Turnera

Camino crítico: reservas → agenda → recordatorios.

- [ ] Reservas online — alcance: reserva por el cliente — governance: MEDIUM — depende de: nada — leer antes: knowledge-base/05_reglas_de_negocio.md
- [ ] Recordatorios — alcance: WhatsApp 24 h antes — governance: HIGH — depende de: Reservas online'
issue=$(gh issue create --title "Roadmap" --body "$ROADMAP" | sed 's|.*/||')

restore() {
  find "$DIR" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
  cp -r "$PRISTINE"/. "$DIR"/
}

# expect NAME WANT_EXIT REGEX
expect() {
  local name="$1" want="$2" re="$3" got output
  output=$(bash "$HERE/check-e2e.sh" check "$DIR" "$SNAP" 2>&1); got=$?
  [ -n "$OUT" ] && printf '%s\nexit=%s\n' "$output" "$got" > "$OUT/selftest-e2e-$name.txt"
  if [ "$got" = "$want" ] && printf '%s' "$output" | grep -qE -- "$re"; then
    echo "ok   $name"
  else
    echo "MAL  $name: esperaba exit=$want y /$re/, obtuve exit=$got"
    printf '%s\n' "$output" | sed 's/^/     | /'
    failures=$((failures + 1))
  fi
  restore
}

expect good 0 'RESULTADO: todo en verde'

rm knowledge-base/03_actores_y_roles.md
expect kb-missing 1 'falta knowledge-base/03_actores_y_roles.md'

printf 'x\n' > knowledge-base/09_decisiones_y_supuestos.md
expect kb-09 1 'sobra knowledge-base/09_decisiones_y_supuestos.md'

sed -i '/05_reglas_de_negocio/d' knowledge-base/README.md
expect kb-index 1 'knowledge-base/README.md no lista 05_reglas_de_negocio'

sed -i '/^## Language/d' GLOSSARY.md
expect glossary 1 "falta la sección '## Language'"

sed -i '/^_Avoid_:/d' GLOSSARY.md
expect glossary-avoid 1 "ningún término tiene '_Avoid_:'"

mv docs/adr/0001-los-turnos-no-se-borran.md docs/adr/adr-1.md
expect adr-name 1 'docs/adr/adr-1.md: el nombre no es NNNN-slug.md'

printf -- '---\nstatus: accepted\n---\n\nSin título.\n' > docs/adr/0001-los-turnos-no-se-borran.md
expect adr-no-title 1 "0001-los-turnos-no-se-borran.md: no tiene título"

mkdir -p "dir con espacio/openspec"
expect openspec-spaces 1 '  dir con espacio/openspec$'

printf '\n# Turnera\n\nCopia del contenido.\n' >> CLAUDE.md
expect claude-md 1 "CLAUDE.md tiene que ser solo '@AGENTS.md'"

sed -i 's/GitHub Issues/Jira/' AGENTS.md
expect agent-skills-changed 1 "'## Agent skills' cambió respecto del snapshot"

sed -i '/^## Agent skills/,$d' AGENTS.md
expect agent-skills-gone 1 "AGENTS.md no tiene '## Agent skills'"

mkdir openspec
expect openspec 1 'FAIL sin openspec/'

printf '{}\n' > .active-orchestrator-state.json
expect state-file 1 '\.active-orchestrator-state\.json'

extra=$(gh issue create --title "Spec de más" --body "x" | sed 's|.*/||')
expect issue-extra 1 'hay 2 issues en el repo de prueba'
gh issue delete "$extra" --yes >/dev/null

gh issue edit "$issue" --body "${ROADMAP/MEDIUM/MEDIO}" >/dev/null
expect issue-old-governance 1 'vocabulario viejo de governance'

gh issue edit "$issue" --body "$(printf '%s' "$ROADMAP" | sed 's/- \[ \] /- /')" >/dev/null
expect issue-no-tasklist 1 "el issue no tiene task list"
gh issue edit "$issue" --body "$ROADMAP" >/dev/null

gh issue close "$issue" >/dev/null 2>&1
expect issue-closed-counts 0 'PASS un solo issue'

echo
if [ $failures = 0 ]; then echo "SELFTEST-E2E: todos los escenarios ok"; exit 0
else echo "SELFTEST-E2E: $failures escenario(s) mal"; exit 1; fi
