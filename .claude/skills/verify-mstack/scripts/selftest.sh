#!/usr/bin/env bash
# Verifica el verificador: inyecta cada falla en una copia descartable de mstack
# y comprueba que check-static.sh falla con el mensaje correcto. El repo real no se toca.
#
# Uso:   bash selftest.sh [OUT_DIR]
#        OUT_DIR = dónde guardar la salida de cada escenario (default: no guarda).
# Exit:  0 si cada escenario se comporta como se espera, 1 si no.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
OUT="${1:-}"
[ -n "$OUT" ] && mkdir -p "$OUT"

SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/verify-mstack-selftest.XXXXXX")"
trap 'rm -rf "$SCRATCH"' EXIT

failures=0

# Copia limpia de lo que lee check-static: skills/, .claude/skills/, NOTICE.md.
fresh_copy() {
  local dst="$SCRATCH/$1"
  mkdir -p "$dst/.claude"
  cp -r "$REPO/skills" "$dst/skills"
  cp -r "$REPO/.claude/skills" "$dst/.claude/skills"
  cp "$REPO/NOTICE.md" "$dst/NOTICE.md"
  echo "$dst"
}

# Skill de fundación falsa pero bien acreditada, para aislar una sola falla por escenario.
add_fake_foundation() {
  local root="$1" body="$2"
  mkdir -p "$root/skills/kb-creator"
  printf -- '---\nname: kb-creator\ndescription: fake para selftest\n---\n\n<!-- Origen: Group-Active-IA/kb-creator. Ver NOTICE.md.\n     Cambios: ninguno. -->\n\n# kb-creator\n\n%s\n' "$body" > "$root/skills/kb-creator/SKILL.md"
  printf '\n## selftest\n\n- `skills/kb-creator` (de `kb-creator`)\n' >> "$root/NOTICE.md"
}

# expect NAME ROOT WANT_EXIT REGEX: corre check-static y compara exit code y salida.
expect() {
  local name="$1" root="$2" want="$3" re="$4" got output
  output=$(bash "$HERE/check-static.sh" "$root" 2>&1); got=$?
  [ -n "$OUT" ] && printf '%s\nexit=%s\n' "$output" "$got" > "$OUT/selftest-$name.txt"
  if [ "$got" = "$want" ] && printf '%s' "$output" | grep -qE "$re"; then
    echo "ok   $name"
  else
    echo "MAL  $name: esperaba exit=$want y /$re/, obtuve exit=$got"
    printf '%s\n' "$output" | sed 's/^/     | /'
    failures=$((failures + 1))
  fi
}

# 0. La copia sin cambios pasa.
r=$(fresh_copy baseline)
expect baseline "$r" 0 'RESULTADO: todo en verde'

# 0b. Una skill de fundación limpia y acreditada pasa.
r=$(fresh_copy foundation-ok)
add_fake_foundation "$r" 'Escribí GLOSSARY.md y docs/adr/.'
expect foundation-ok "$r" 0 'PASS fundación sin OpenSpec'

# 1. Mención a /opsx en el cuerpo de una skill de fundación.
r=$(fresh_copy opsx)
add_fake_foundation "$r" 'Al terminar, corré /opsx:propose.'
expect opsx "$r" 1 'skills/kb-creator/SKILL.md:[0-9]+:.*/opsx:propose'

# 2. Archivo de estado del orquestador.
r=$(fresh_copy state)
add_fake_foundation "$r" 'Leé .active-orchestrator-state.json.'
expect state "$r" 1 'FAIL fundación sin OpenSpec'

# 2b. El bloque Origen puede nombrar OpenSpec en "Cambios:" (política elegida).
r=$(fresh_copy origin-exempt)
add_fake_foundation "$r" 'Contenido limpio.'
sed -i 's/Cambios: ninguno\./Cambios: sacada la dependencia de OpenSpec y CHANGES.md./' "$r/skills/kb-creator/SKILL.md"
expect origin-exempt "$r" 0 'PASS fundación sin OpenSpec'

# 2c. Pero una mención fuera del bloque, aunque esté justo debajo, cuenta.
r=$(fresh_copy after-origin)
add_fake_foundation "$r" 'Ver openspec/ para el detalle.'
sed -i 's/Cambios: ninguno\./Cambios: sacada la dependencia de OpenSpec./' "$r/skills/kb-creator/SKILL.md"
expect after-origin "$r" 1 'skills/kb-creator/SKILL.md:[0-9]+:Ver openspec/'

# 2d. Un archivo sin bloque Origen (references/) se revisa entero.
r=$(fresh_copy reference)
add_fake_foundation "$r" 'Contenido limpio.'
mkdir -p "$r/skills/kb-creator/references"
printf 'Generá CHANGES.md al final.\n' > "$r/skills/kb-creator/references/extra.md"
expect reference "$r" 1 'skills/kb-creator/references/extra.md:1:'

# 3. name: distinto de la carpeta.
r=$(fresh_copy name)
sed -i 's/^name: council/name: consejo/' "$r/skills/council/SKILL.md"
expect name "$r" 1 "skills/council/SKILL.md: name: 'consejo' pero la carpeta es 'council'"

# 4. Derivada sin entrada en NOTICE.
r=$(fresh_copy notice)
sed -i '/^- `skills\/council`/d' "$r/NOTICE.md"
expect notice "$r" 1 'skills/council: tiene Origen pero NOTICE.md no la lista'

# 5. Skill de fundación sin encabezado Origen.
r=$(fresh_copy origin)
add_fake_foundation "$r" 'Contenido.'
sed -i '/<!-- Origen:/,/-->/d' "$r/skills/kb-creator/SKILL.md"
expect origin "$r" 1 'skills/kb-creator/SKILL.md: es derivada pero no tiene el encabezado'

echo
if [ $failures = 0 ]; then echo "SELFTEST: todos los escenarios ok"; exit 0
else echo "SELFTEST: $failures escenario(s) mal"; exit 1; fi
