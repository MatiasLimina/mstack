#!/usr/bin/env bash
# Verificaciones finales de la corrida de punta a punta de la fundación (spec #10,
# "Punto de prueba 1"). Lee solo disco y GitHub; no modifica nada.
#
# Uso:
#   bash check-e2e.sh snapshot TEST_REPO OUT_FILE
#       Guarda la sección "## Agent skills" de TEST_REPO/AGENTS.md en OUT_FILE.
#       Correlo justo después de /setup-matt-pocock-skills.
#   bash check-e2e.sh check TEST_REPO SNAPSHOT_FILE
#       Corre todas las verificaciones. Exige que "## Agent skills" siga
#       idéntica a la del snapshot: sin él, una sección reescrita pasaría.
# Exit: 0 todo pasa, 1 alguna verificación falla, 2 uso incorrecto.

set -u

usage() { sed -n '2,13p' "$0" >&2; exit 2; }

# Sección "## Agent skills" (encabezado incluido) hasta el próximo "## " o el fin.
agent_skills_section() {
  tr -d '\r' < "$1" | awk '/^## Agent skills[ \t]*$/ {on=1; print; next} on && /^## / {exit} on {print}'
}

mode="${1:-}"; repo="${2:-}"
[ -n "$mode" ] && [ -n "$repo" ] && [ -d "$repo" ] || usage
repo="${repo%/}"

if [ "$mode" = snapshot ]; then
  out="${3:-}"; [ -n "$out" ] || usage
  sec=$(agent_skills_section "$repo/AGENTS.md" 2>/dev/null)
  [ -n "$sec" ] || { echo "ERROR: $repo/AGENTS.md no tiene '## Agent skills'. ¿Corriste /setup-matt-pocock-skills?" >&2; exit 1; }
  printf '%s\n' "$sec" > "$out"
  echo "snapshot guardado en $out ($(wc -l < "$out") líneas)"
  exit 0
fi
[ "$mode" = check ] || usage
snapshot="${3:-}"
[ -f "$snapshot" ] || { echo "ERROR: falta el snapshot de '## Agent skills' (check-e2e.sh snapshot ...)." >&2; usage; }

status=0
pass() { echo "PASS $1"; }
fail() { echo "FAIL $1"; shift; for l in "$@"; do echo "  $l"; done; status=1; }

echo "verify-mstack check-e2e sobre $repo"

# 1. KB: 9 canónicos con numeración original, sin 09.
KB="$repo/knowledge-base"
CANON="01_vision_y_objetivos 02_descripcion_general 03_actores_y_roles 04_modelo_de_datos 05_reglas_de_negocio 06_funcionalidades 07_flujos_principales 08_arquitectura_propuesta 10_preguntas_abiertas"
missing=()
for f in $CANON; do [ -f "$KB/$f.md" ] || missing+=("falta knowledge-base/$f.md"); done
for f in "$KB"/09_*; do [ -e "$f" ] && missing+=("sobra ${f#$repo/}: el 09 tiene que quedar vacío"); done
if [ -f "$KB/README.md" ]; then
  for f in $CANON GLOSSARY.md docs/adr; do
    grep -qF "$f" "$KB/README.md" || missing+=("knowledge-base/README.md no lista $f")
  done
else missing+=("falta el índice knowledge-base/README.md")
fi
if [ ${#missing[@]} = 0 ]; then pass "knowledge-base/ con los 9 canónicos, sin 09 y con índice"
else fail "knowledge-base/ con los 9 canónicos, sin 09 y con índice" "${missing[@]}"; fi

# 2. GLOSSARY.md con el formato de domain-modeling de Matt.
G="$repo/GLOSSARY.md"; probs=()
if [ ! -f "$G" ]; then probs+=("no existe GLOSSARY.md en la raíz")
else
  tr -d '\r' < "$G" | head -n 1 | grep -q '^# ' || probs+=("la primera línea no es '# <Contexto>'")
  tr -d '\r' < "$G" | grep -q '^## Language' || probs+=("falta la sección '## Language'")
  tr -d '\r' < "$G" | grep -qE '^\*\*[^*]+\*\*:' || probs+=("no hay ningún término '**Término**:'")
  tr -d '\r' < "$G" | grep -qE '^_Avoid_:' || probs+=("ningún término tiene '_Avoid_:' (el formato pide elegir una palabra y listar las que se evitan)")
fi
if [ ${#probs[@]} = 0 ]; then pass "GLOSSARY.md con formato de Matt"; else fail "GLOSSARY.md con formato de Matt" "${probs[@]}"; fi

# 3. docs/adr/ con NNNN-slug.md, cada uno con título '# '.
A="$repo/docs/adr"; probs=(); n=0
if [ ! -d "$A" ]; then probs+=("no existe docs/adr/")
else
  for f in "$A"/*; do
    [ -e "$f" ] || continue
    b=$(basename "$f"); n=$((n + 1))
    printf '%s' "$b" | grep -qE '^[0-9]{4}-[a-z0-9-]+\.md$' || probs+=("docs/adr/$b: el nombre no es NNNN-slug.md")
    tr -d '\r' < "$f" | grep -qE '^# ' || probs+=("docs/adr/$b: no tiene título '# <decisión>'")
  done
  [ $n -gt 0 ] || probs+=("docs/adr/ está vacío")
fi
if [ ${#probs[@]} = 0 ]; then pass "docs/adr/ con formato de Matt ($n ADRs)"; else fail "docs/adr/ con formato de Matt" "${probs[@]}"; fi

# 4. Exactamente un issue (el de roadmap), con task list y governance en inglés.
probs=()
count=$(cd "$repo" && gh issue list --state all --limit 100 --json number --jq 'length' 2>&1)
if ! printf '%s' "$count" | grep -qE '^[0-9]+$'; then probs+=("gh issue list falló: $count")
else
  if [ "$count" != 1 ]; then
    probs+=("hay $count issues en el repo de prueba; tiene que haber exactamente 1 (el roadmap)")
  else
    body=$(cd "$repo" && gh issue list --state all --limit 1 --json body --jq '.[0].body')
    printf '%s' "$body" | grep -qE '^\s*- \[ \] ' || probs+=("el issue no tiene task list ('- [ ] ...')")
    printf '%s' "$body" | grep -qE '\b(LOW|MEDIUM|HIGH|CRITICAL)\b' || probs+=("el issue no usa niveles LOW/MEDIUM/HIGH/CRITICAL")
    hit=$(printf '%s' "$body" | grep -nE '\b(BAJO|MEDIO|ALTO|CR[IÍ]TICO)\b' | head -n 3)
    [ -z "$hit" ] || probs+=("el issue usa el vocabulario viejo de governance: $hit")
  fi
fi
if [ ${#probs[@]} = 0 ]; then pass "un solo issue: el roadmap, con task list y LOW/MEDIUM/HIGH/CRITICAL"
else fail "un solo issue de roadmap" "${probs[@]}"; fi

# 5. AGENTS.md con contenido y CLAUDE.md == '@AGENTS.md'.
probs=()
[ -s "$repo/AGENTS.md" ] || probs+=("AGENTS.md no existe o está vacío")
if [ -f "$repo/CLAUDE.md" ]; then
  c=$(tr -d '\r' < "$repo/CLAUDE.md" | sed -e '/^[[:space:]]*$/d')
  [ "$c" = "@AGENTS.md" ] || probs+=("CLAUDE.md tiene que ser solo '@AGENTS.md'; tiene: $(printf '%s' "$c" | head -c 120)")
else probs+=("CLAUDE.md no existe")
fi
if [ -f "$repo/AGENTS.md" ]; then
  other=$(tr -d '\r' < "$repo/AGENTS.md" | grep -c '^## ' )
  [ "$other" -ge 2 ] || probs+=("AGENTS.md tiene $other secciones '## '; esperaba el contenido de agent-instruction además de '## Agent skills'")
fi
if [ ${#probs[@]} = 0 ]; then pass "AGENTS.md es la fuente y CLAUDE.md lo importa"; else fail "AGENTS.md + CLAUDE.md" "${probs[@]}"; fi

# 6. '## Agent skills' sobrevive a la segunda corrida de agent-instruction.
probs=()
sec=$(agent_skills_section "$repo/AGENTS.md" 2>/dev/null)
[ -n "$sec" ] || probs+=("AGENTS.md no tiene '## Agent skills'")
if [ -n "$sec" ]; then
  d=$(diff <(tr -d '\r' < "$snapshot") <(printf '%s\n' "$sec"))
  [ -z "$d" ] || probs+=("'## Agent skills' cambió respecto del snapshot:" "$d")
fi
if [ ${#probs[@]} = 0 ]; then pass "'## Agent skills' presente e idéntica al snapshot"; else fail "'## Agent skills' sobrevive" "${probs[@]}"; fi

# 7. Nada de OpenSpec ni estado de orquestador.
leftovers=()
while IFS= read -r p; do leftovers+=("${p#$repo/}"); done < <(find "$repo" -path "$repo/.git" -prune -o \( -name openspec -type d -print \) -o \( -name '*orchestrator-state*.json' -print \))
if [ ${#leftovers[@]} = 0 ]; then pass "sin openspec/ ni *-orchestrator-state.json"
else fail "sin openspec/ ni *-orchestrator-state.json" "${leftovers[@]}"; fi

[ $status = 0 ] && echo "RESULTADO: todo en verde" || echo "RESULTADO: hay verificaciones en rojo"
exit $status
