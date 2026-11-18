#!/usr/bin/env bash
# ¿Vale la pena verificar con esta máquina y este checkout? Solo lee; no cambia nada.
#
# Uso:  bash doctor.sh [TEST_REPO]
#       Con TEST_REPO, además revisa el repo de prueba de la corrida de punta a punta.
# Exit: 0 listo, 1 hay algo que arreglar antes de verificar.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
status=0
ok()   { echo "ok   $1"; }
bad()  { echo "MAL  $1"; status=1; }
warn() { echo "ojo  $1"; }

for t in bash git awk sed grep find diff; do
  command -v "$t" >/dev/null 2>&1 && ok "$t disponible" || bad "falta $t en PATH (corré los scripts desde Git Bash)"
done

ROOT=$(git -C "$HERE" rev-parse --show-toplevel 2>/dev/null)
if [ -n "$ROOT" ] && [ -f "$ROOT/NOTICE.md" ] && [ -d "$ROOT/skills" ]; then
  ok "checkout de mstack en $ROOT (rama $(git -C "$ROOT" branch --show-current), $(git -C "$ROOT" rev-parse --short HEAD))"
  dirty=$(git -C "$ROOT" status --porcelain | wc -l)
  [ "$dirty" = 0 ] || warn "$dirty archivo(s) sin commitear: los chequeos ven el working tree, no HEAD"
else
  bad "este script no está dentro de un checkout de mstack"
fi

if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    ok "gh autenticado ($(gh --version | head -n 1))"
  else
    bad "gh no está autenticado ('gh auth login'); el punto de prueba 1 lo necesita"
  fi
else
  bad "falta gh; el punto de prueba 1 lo necesita"
fi

TEST="${1:-}"
REPO="${MSTACK_VERIFY_REPO:-MatiasLimina/Verify-mstack}"
if [ -n "$TEST" ]; then
  if [ ! -d "$TEST/.git" ]; then bad "$TEST no es un repo git"
  else
    remote=$(cd "$TEST" && gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)
    case "$remote" in
      "$REPO") ok "sandbox $TEST -> github.com/$remote" ;;
      "") bad "$TEST no tiene remote en GitHub" ;;
      *) bad "$TEST apunta a $remote, que no es el sandbox ($REPO). No lo manejes." ;;
    esac
    case "$(cd "$TEST" && pwd -W 2>/dev/null || pwd)" in
      "$ROOT"/*) bad "$TEST está dentro de mstack: la sesión de prueba cargaría el AGENTS.md de mstack" ;;
    esac
  fi
fi

exit $status
