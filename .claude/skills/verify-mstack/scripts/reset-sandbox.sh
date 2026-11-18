#!/usr/bin/env bash
# Deja el repo sandbox de la corrida de punta a punta en su estado inicial:
# sin issues (ni abiertos ni cerrados), main en el primer commit, sin archivos
# sueltos y sin otras ramas en GitHub. Borra contenido de GitHub: solo actúa
# si el remote de MSTACK_VERIFY_DIR es exactamente MSTACK_VERIFY_REPO.
#
# Uso:  bash reset-sandbox.sh [--dry-run]
# Env:  MSTACK_VERIFY_DIR   (default D:/APruebas/Verify-mstack)
#       MSTACK_VERIFY_REPO  (default MatiasLimina/Verify-mstack)
# Exit: 0 sandbox limpio, 1 algo quedó sucio, 2 el remote no es el sandbox (no tocó nada).

set -u
DIR="${MSTACK_VERIFY_DIR:-D:/APruebas/Verify-mstack}"
REPO="${MSTACK_VERIFY_REPO:-MatiasLimina/Verify-mstack}"
dry=0; [ "${1:-}" = --dry-run ] && dry=1
run() { if [ $dry = 1 ]; then echo "(dry-run) $*"; else "$@"; fi; }

cd "$DIR" 2>/dev/null || { echo "ERROR: no existe $DIR" >&2; exit 2; }
actual=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)
if [ "$actual" != "$REPO" ]; then
  echo "ERROR: $DIR apunta a '${actual:-sin remote}', no a $REPO. No toco nada." >&2
  exit 2
fi
echo "reset del sandbox $REPO en $DIR"

# 1. Issues: todos, cerrados incluidos ("exactamente un issue" cuenta todos).
for n in $(gh issue list --state all --limit 500 --json number --jq '.[].number'); do
  run gh issue delete "$n" --yes
done

# 2. Git: main en el primer commit. Si el repo está vacío, crea ese commit.
if ! git rev-parse --verify -q HEAD >/dev/null; then
  run git commit -q --allow-empty -m "init: sandbox de verify-mstack"
fi
if git rev-parse --verify -q HEAD >/dev/null; then
  root=$(git rev-list --max-parents=0 HEAD | tail -n 1)
  run git checkout -q -B main "$root"
  run git clean -qfdx
  run git push -q --force origin main
  for b in $(git ls-remote --heads origin | sed 's|.*refs/heads/||' | grep -vx main); do
    run git push -q origin --delete "$b"
  done
fi

[ $dry = 1 ] && exit 0

# 3. Comprobar el resultado.
issues=$(gh issue list --state all --limit 500 --json number --jq length)
files=$(git ls-files | wc -l)
loose=$(git status --porcelain --ignored | wc -l)
branches=$(git ls-remote --heads origin | wc -l)
echo "issues=$issues archivos=$files sueltos=$loose ramas_remotas=$branches head=$(git rev-parse --short HEAD)"
if [ "$issues" = 0 ] && [ "$files" = 0 ] && [ "$loose" = 0 ] && [ "$branches" = 1 ]; then
  echo "SANDBOX LIMPIO"
else
  echo "SANDBOX SUCIO: revisá los contadores de arriba"; exit 1
fi
