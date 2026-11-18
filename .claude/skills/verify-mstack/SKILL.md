---
name: verify-mstack
description: Verifica cambios en mstack (repo de skills para agentes) antes de mergearlos. Corre chequeos estáticos sobre skills/ y NOTICE.md (fundación sin OpenSpec, name: igual a la carpeta, derivadas acreditadas) y guía la corrida de punta a punta de la cadena de fundación sobre un repo de prueba en GitHub. Usala en el paso verify de cualquier ticket de mstack, o cuando el usuario pida verificar el repo o la fundación.
---

# verify-mstack

mstack no es una app: es un repo de skills (Markdown + algún script) que se
copian a `~/.claude/skills/`. Lo que un usuario "toca" son dos cosas:

1. **El repo en sí.** Hay chequeos estáticos baratos, sin agentes ni red. Corren siempre.
2. **La cadena de fundación ya instalada**, corriendo sobre un proyecto nuevo:
   `discovery-research` → `kb-creator` → `roadmap-generator` →
   `agent-instruction` → `/setup-matt-pocock-skills` → `agent-instruction`.
   Es interactiva, la maneja el usuario y deja resultados en disco y en GitHub.
   Solo se corre cuando el cambio toca la fundación (o en el ticket #19).

Todos los scripts son bash: corrélos con la herramienta Bash (Git Bash en
Windows), nunca en PowerShell. Rutas relativas a la raíz del repo.

## Launch

No hay servidor. Para los chequeos estáticos alcanza con el checkout. Elegí un
id de corrida y una carpeta de evidencia:

```bash
RUN_ID=$(date +%Y%m%d-%H%M%S)
OUT=".verify-artifacts/$RUN_ID"; mkdir -p "$OUT"
```

`.verify-artifacts/` está en `.gitignore`. La corrida de punta a punta tiene su
propio launch (repo de prueba + skills instaladas desde el repo), descripto en
[features/foundation-chain.md](features/foundation-chain.md).

## Doctor

Corrélo primero y cada vez que algo no cierre:

```bash
bash .claude/skills/verify-mstack/scripts/doctor.sh                # máquina + checkout
bash .claude/skills/verify-mstack/scripts/doctor.sh "$TEST_REPO"   # + repo de prueba
```

Un `MAL` bloquea la verificación. Un `ojo` es una advertencia; la más común es
el working tree sucio (los chequeos ven archivos sin commitear).

## Sandbox de la corrida de punta a punta

La corrida de punta a punta usa siempre el mismo repo, que no se versiona en mstack:

- Local: `D:/APruebas/Verify-mstack` (`MSTACK_VERIFY_DIR`).
- GitHub: `MatiasLimina/Verify-mstack`, privado (`MSTACK_VERIFY_REPO`).
- Producto: [fixtures/peluquerias.md](fixtures/peluquerias.md), con las respuestas fijas de la cadena.

Está fuera de mstack a propósito: una sesión abierta debajo de mstack cargaría
su `AGENTS.md` y contaminaría la prueba. Antes de cada corrida,
`scripts/reset-sandbox.sh` lo deja sin issues y con `main` en el primer commit.
El script borra contenido de GitHub, pero se niega a correr si el remote no es
`MSTACK_VERIFY_REPO`.

## Drive

Mapa completo en [features/README.md](features/README.md). Lo mínimo para
cualquier PR de mstack:

```bash
bash .claude/skills/verify-mstack/scripts/check-static.sh 2>&1 | tee "$OUT/static.txt"; echo "exit=${PIPESTATUS[0]}" | tee -a "$OUT/static.txt"
bash .claude/skills/verify-mstack/scripts/selftest.sh "$OUT" 2>&1 | tee "$OUT/selftest.txt"
```

- `check-static.sh [ROOT]`: tres chequeos, exit 0/1. Cada FAIL lista `archivo:línea` y el motivo.
- `selftest.sh [OUT]`: inyecta cada falla (una mención a `/opsx`, un `name:` distinto, una entrada de NOTICE que falta, un Origen que falta) en una copia temporal y comprueba que `check-static` la atrape. Corrélo si tocaste `check-static.sh`.
- `check-e2e.sh snapshot|check TEST_REPO ...`: verificaciones finales de la corrida de punta a punta. Ver el feature.

Resultado esperado según el estado del repo:

| Estado | `check-static` |
|---|---|
| Antes de #13 (fundación fuera del repo) | todo PASS; "todavía no están en el repo" lista las 5 skills |
| Después de #13, antes de #14-#17 | FAIL solo en "fundación sin OpenSpec", con cada línea que adaptan esos tickets |
| Después de #17 | todo PASS |

## Evidence

Todo va a `.verify-artifacts/$RUN_ID/`:

- `static.txt`: salida completa de `check-static` y su exit code.
- `selftest.txt` y `selftest-<escenario>.txt`: la salida de cada falla inyectada.
- En la corrida de punta a punta: `agent-skills.before.md`, `e2e.txt`, `tree.txt`, `issues.json` y `AGENTS.md` / `CLAUDE.md` copiados del repo de prueba (ver el feature).

Estándares de prueba:

- Un chequeo estático en verde prueba la forma del repo, no que la fundación funcione. Si el cambio toca una skill de fundación, la prueba es la corrida de punta a punta.
- En la corrida de punta a punta, la prueba es lo que quedó en disco y en GitHub (`gh`), no lo que el agente dijo que hizo.
- Las skills que se prueban son las del repo, instaladas en `~/.claude/skills/`, no las que ya estaban instaladas desde active-stack.
- Citá la salida real en el reporte: exit code y líneas FAIL textuales.

## Cleanup

Los chequeos estáticos no crean nada fuera de `$OUT`; `selftest.sh` borra su
copia temporal al salir. La corrida de punta a punta tiene su cleanup en el
feature: resetear el sandbox y restaurar las skills instaladas. El sandbox no
se borra. Nunca borres `.verify-artifacts/`: ahí queda la prueba.

## Helpers

| Script | Invocación | Qué hace |
|---|---|---|
| `scripts/doctor.sh` | `bash .claude/skills/verify-mstack/scripts/doctor.sh [TEST_REPO]` | Chequeo read-only de herramientas, checkout, `gh` y repo de prueba. |
| `scripts/check-static.sh` | `bash .claude/skills/verify-mstack/scripts/check-static.sh [ROOT]` | Chequeos estáticos; `ROOT` permite correrlos sobre otra copia. |
| `scripts/selftest.sh` | `bash .claude/skills/verify-mstack/scripts/selftest.sh [OUT]` | Prueba que cada chequeo estático falla cuando debe. |
| `scripts/selftest-e2e.sh` | `bash .claude/skills/verify-mstack/scripts/selftest-e2e.sh [OUT]` | Arma a mano en el sandbox una salida buena de la fundación y rompe cada cosa para probar `check-e2e`. Toca issues del sandbox y lo resetea al terminar. Corrélo si tocaste `check-e2e.sh`. |
| `scripts/reset-sandbox.sh` | `bash .claude/skills/verify-mstack/scripts/reset-sandbox.sh [--dry-run]` | Borra los issues del sandbox y deja `main` en su primer commit. Termina con `SANDBOX LIMPIO`. |
| `scripts/check-e2e.sh` | `bash .claude/skills/verify-mstack/scripts/check-e2e.sh snapshot TEST_REPO FILE` / `check TEST_REPO FILE` | Verificaciones de disco y GitHub de la corrida de punta a punta. |
