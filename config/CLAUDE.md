# CLAUDE.md global (mstack)

Instrucciones que aplican a todas las sesiones y a todos los agentes. Lo que
se dispara por intención vive en una skill, no acá.

## Shell y rutas (Windows)

Mi terminal es PowerShell. Todo comando que me pases para que lo corra YO va
en sintaxis PowerShell y con rutas Windows (`C:\Users\...`). Nunca `/c/...`,
`~/...` ni sintaxis bash (`rm -rf`, `export`, `&&` encadenado, heredocs).

Tu herramienta Bash interna es Git Bash: ahí sí podés usar `/c/...`. No
mezcles: lo que corrés vos ≠ lo que me pasás a mí. Si dudás, usá rutas con
barra normal y entre comillas (`"C:/Users/..."`): funcionan en ambos shells.

Equivalentes frecuentes: borrar carpeta → `Remove-Item -Recurse -Force "C:\..."`;
quitar worktree → `git worktree remove "C:\..."`; variable de entorno →
`$env:VAR = "valor"`.

## Workflow

```
grill-with-docs ─┬─ (trabado / dudas de diseño) ──→ council
                 ▼
to-spec → implement + tdd ── (mismo error 2 veces) ──→ advisor
                 ▼
verify-<proyecto>
                 ▼
gate final (según governance, ver abajo)
                 ▼
file-pr → babysit-pr        ← full-stop / full-send encadenan desde verify
```

- Antes de implementar, ubicá el estado del proyecto: leé su `CLAUDE.md` /
  `AGENTS.md` y, si existen, `knowledge-base/` y `CHANGES.md`.
- Fundación (solo proyectos grandes y vacíos): `discovery-research` →
  `kb-creator` → `roadmap-generator` → `agent-instruction`.
- Las skills de Matt Pocock (`grill-with-docs`, `to-spec`, `implement`, `tdd`,
  `code-review`) vienen del plugin `mattpocock-skills`: invocalas con prefijo (`mattpocock-skills:code-review`, no el `/code-review` built-in
  de Claude Code). En un proyecto nuevo, corré antes
  `mattpocock-skills:setup-matt-pocock-skills`.
- `verify-<proyecto>` se crea con `create-verification-skill` (pstack) si el
  proyecto no la tiene.
- Implementá test-first con `mattpocock-skills:tdd`. Nunca escribas aserciones
  triviales (tautologías, chequeos solo de tipo).
- Un proyecto que use OpenSpec se trabaja con la skill opt-in
  `opsx-orchestrator`; fuera de ese caso, OpenSpec no aplica.

## Delegación

Delegá cuando el trabajo inflaría tu contexto sin necesidad:

- Leer 1-3 archivos para decidir o verificar → inline.
- Explorar 4+ archivos, barridos de grep, docs → agente `scout` (Haiku).
- Correr tests o builds largos, o escribir una feature en varios archivos →
  sub-agente, con el contexto completo en el brief (arranca en frío).
- En dominios CRITICAL/HIGH leé los archivos clave vos, no solo el resumen
  de `scout`.

## Governance por dominio

Antes de cualquier acción no trivial, identificá el nivel del dominio:

| Nivel | Dominios típicos | Comportamiento |
|---|---|---|
| CRITICAL | Auth, billing, seguridad, audit logs | Solo análisis; no escribís código sin aprobación explícita. |
| HIGH | Config que afecta datos del usuario, inyección en dotfiles, backup/restore | Proponé y esperá review antes de escribir. |
| MEDIUM | Lógica de negocio, adapters, pipelines | Implementá por pasos; mostrá las decisiones no obvias. |
| LOW | CRUDs simples, catálogos, tipos, utilidades read-only | Autonomía total si los tests pasan. |

### Gate final

Antes de declarar un cambio terminado o commitear, revisá el diff según el
nivel más alto que toque:

| Nivel | Revisión |
|---|---|
| LOW | Tests en verde |
| MEDIUM | `mattpocock-skills:code-review` |
| HIGH | `mattpocock-skills:code-review` + `gemini-loop` |
| CRITICAL | `mattpocock-skills:code-review` + `gemini-loop` + `council` |

Si no hay ruta a Gemini (fuera de T3 Code), `gemini-loop` y `council` no
corren: reportá el bloqueo y sugerí el agente `advisor` sobre `git diff`.
Corré el `advisor` solo si el usuario acepta. Nunca corras `advisor` y
`council` sobre el mismo diff.

## Advisor

El agente `advisor` (Opus, read-only) se consulta solo en estos casos:

- **REPEATED_FAILURE**: el mismo error de test o compilación falla 2 veces
  seguidas en GREEN/REFACTOR (el fallo esperado de RED no cuenta). Consultalo
  antes del tercer intento con el error, los archivos y lo que probaste.
- **Sin Gemini**: como reemplazo del gate final, si el usuario lo acepta (ver
  arriba).

Arranca en frío: pasale paths, el cambio y el motivo de la consulta. Veredicto
BLOCK → no sigas sin confirmación del usuario. CONCERNS → resolvelos o
mostralos.

## Preferencias mstack

Las skills leen estos valores; si falta alguno, usan su default.

| Phase | Modelo | Effort |
|---|---|---|
| orchestrator | opus | medium |
| scout | haiku | medium |
| implement | sonnet | medium (high si governance HIGH/CRITICAL) |
| advisor | opus | high |
| default | sonnet | medium |

Si no tenés acceso al modelo asignado, usá `sonnet` y seguí.

Overrides de skills: ninguno. `gemini-loop`, `council` y `babysit-pr` usan
sus defaults. Para cambiar uno, agregalo acá como `skill: valor` (p. ej.
`council — tercer miembro: <proveedor/modelo>`); solo lo que difiera del default.

## Memoria (engram)

Seguí las instrucciones que inyecta el servidor MCP de engram (guardado
proactivo, recuperar contexto al arrancar con `mem_context`). Además:

- Antes de cerrar la sesión, `mem_session_summary` con Goal, Discoveries,
  Accomplished, Next Steps y Relevant Files.
- Después de una compactación, primero `mem_session_summary` con el resumen
  compactado y recién después `mem_context`.

Al pushear un repo que versiona `.engram/`: corré `engram sync` antes del
push y commiteá `.engram/`. Al clonar o pullear uno: `engram sync --import`.
Nunca `engram sync --all` (mezcla la memoria de todos los proyectos). Antes de
versionar `.engram/` en un repo público, confirmá con el usuario; verificá que
no esté ignorado con `git check-ignore .engram`.
