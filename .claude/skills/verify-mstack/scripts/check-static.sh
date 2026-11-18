#!/usr/bin/env bash
# Chequeos estáticos de mstack. No corre agentes ni toca la red.
#
# Uso:   bash check-static.sh [ROOT]
#        ROOT = raíz de un checkout de mstack (default: el repo que contiene este script).
# Salida: un bloque PASS/FAIL por chequeo, con archivo:línea de cada problema.
# Exit:   0 si todo pasa, 1 si falla algún chequeo, 2 si ROOT no es un checkout de mstack.

set -u

ROOT="${1:-$(git -C "$(dirname "$0")" rev-parse --show-toplevel)}"
ROOT="${ROOT%/}"

if [ ! -d "$ROOT/skills" ] || [ ! -f "$ROOT/NOTICE.md" ]; then
  echo "ERROR: $ROOT no parece un checkout de mstack (falta skills/ o NOTICE.md)." >&2
  exit 2
fi

# Skills de fundación (spec #10). Todas derivan de repos de terceros.
FOUNDATION="discovery-research kb-creator roadmap-generator web-scraper agent-instruction"

# Lo que una skill de fundación no puede mencionar.
FORBIDDEN_RE='openspec|/opsx|CHANGES\.md|orchestrator-state'

status=0
fail() { status=1; }

# Directorios de skill que existen en ROOT (skills/ del stack + skills locales del repo).
skill_dirs() {
  for d in "$ROOT"/skills/*/ "$ROOT"/.claude/skills/*/; do
    [ -f "$d/SKILL.md" ] && echo "${d%/}"
  done
}

# Imprime "N:texto" por cada línea de FILE que contiene algo de FORBIDDEN_RE.
# Exime el bloque <!-- Origen: ... -->: su línea "Cambios:" tiene que poder
# nombrar lo que se sacó (lo pide la licencia). Fuera de ese bloque, todo cuenta.
forbidden_hits() {
  local file="$1"
  # La regex va por el entorno: "awk -v" interpretaría el "\." de CHANGES\.md.
  tr -d '\r' < "$file" | FRE="$FORBIDDEN_RE" awk '
    BEGIN { re = ENVIRON["FRE"] }
    /<!-- Origen:/ { skip = 1 }
    !skip && tolower($0) ~ tolower(re) { print NR ":" $0 }
    skip && /-->/ { skip = 0 }'
}

# --- Chequeo 1: fundación sin OpenSpec ni estado de orquestador -------------
check_foundation_clean() {
  local out="" missing="" s f hits
  for s in $FOUNDATION; do
    if [ ! -d "$ROOT/skills/$s" ]; then
      missing="$missing $s"
      continue
    fi
    while IFS= read -r f; do
      hits=$(forbidden_hits "$f")
      [ -n "$hits" ] && out="$out$(printf '%s\n' "$hits" | sed "s|^|  ${f#$ROOT/}:|")"$'\n'
    done < <(find "$ROOT/skills/$s" -type f)
  done
  if [ -n "$out" ]; then
    echo "FAIL fundación sin OpenSpec: estas líneas mencionan OpenSpec, /opsx, CHANGES.md o un archivo de estado del orquestador:"
    printf '%s' "$out"
    fail
  else
    echo "PASS fundación sin OpenSpec"
  fi
  [ -n "$missing" ] && echo "  (todavía no están en el repo, no se revisan:$missing)"
}

# --- Chequeo 2: name: del frontmatter == carpeta ---------------------------
frontmatter_name() {
  # Devuelve el valor de name: dentro del primer bloque --- ... ---, o nada.
  tr -d '\r' < "$1" | awk '
    NR==1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    /^name:[ \t]*/ { sub(/^name:[ \t]*/, ""); gsub(/^["'\'']|["'\'']$/, ""); print; exit }'
}

check_names() {
  local out="" d dir name
  while IFS= read -r d; do
    dir=$(basename "$d")
    name=$(frontmatter_name "$d/SKILL.md")
    if [ -z "$name" ]; then
      out="$out  ${d#$ROOT/}/SKILL.md: no tiene frontmatter con name: (sin eso la skill no se registra)"$'\n'
    elif [ "$name" != "$dir" ]; then
      out="$out  ${d#$ROOT/}/SKILL.md: name: '$name' pero la carpeta es '$dir'"$'\n'
    fi
  done < <(skill_dirs)
  if [ -n "$out" ]; then
    echo "FAIL name: coincide con la carpeta:"
    printf '%s' "$out"
    fail
  else
    echo "PASS name: coincide con la carpeta"
  fi
}

# --- Chequeo 3: derivadas con encabezado Origen y entrada en NOTICE --------
has_origin() { head -n 20 "$1" | grep -q '<!-- Origen:'; }

notice_skills() {
  # Primer path de cada viñeta "- `skills/<x>...`" de NOTICE.md -> <x>
  tr -d '\r' < "$ROOT/NOTICE.md" | sed -n 's|^- `skills/\([^`/]*\).*|\1|p' | sort -u
}

check_derived() {
  local out="" d name listed
  listed=$(notice_skills)
  # a) Toda skill con Origen, y toda skill de fundación presente, está en NOTICE y tiene Origen.
  while IFS= read -r d; do
    name=$(basename "$d")
    case "$d" in "$ROOT"/.claude/*) continue ;; esac
    local is_foundation=0
    case " $FOUNDATION " in *" $name "*) is_foundation=1 ;; esac
    if has_origin "$d/SKILL.md" || [ $is_foundation = 1 ]; then
      has_origin "$d/SKILL.md" || out="$out  skills/$name/SKILL.md: es derivada pero no tiene el encabezado <!-- Origen: ... --> en las primeras 20 líneas"$'\n'
      printf '%s\n' "$listed" | grep -qx "$name" || out="$out  skills/$name: tiene Origen pero NOTICE.md no la lista como - \`skills/$name\`"$'\n'
    fi
  done < <(skill_dirs)
  # b) Toda entrada de NOTICE apunta a una skill que existe y tiene Origen.
  for name in $listed; do
    if [ ! -f "$ROOT/skills/$name/SKILL.md" ]; then
      out="$out  NOTICE.md: lista skills/$name pero esa skill no existe"$'\n'
    elif ! has_origin "$ROOT/skills/$name/SKILL.md"; then
      out="$out  NOTICE.md: lista skills/$name pero su SKILL.md no tiene encabezado Origen"$'\n'
    fi
  done
  if [ -n "$out" ]; then
    echo "FAIL derivadas con Origen y NOTICE:"
    printf '%s' "$out"
    fail
  else
    echo "PASS derivadas con Origen y NOTICE"
  fi
}

echo "verify-mstack check-static sobre $ROOT"
check_foundation_clean
check_names
check_derived
[ $status = 0 ] && echo "RESULTADO: todo en verde" || echo "RESULTADO: hay chequeos en rojo"
exit $status
