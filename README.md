# mstack

Mi stack personal de skills para agentes (Claude Code y T3 Code), armado
tomando lo que más me sirve de otros stacks y adaptándolo a mi forma de
trabajar.

## Skills

| Skill | Decí | Qué hace | Origen |
|---|---|---|---|
| `gemini-loop` | "gemini loop" | Revisa un cambio con un revisor Gemini en loop hasta que los dos agentes estén de acuerdo. | Adaptada de `sol-loop` ([tstack](https://github.com/t3dotgg/tstack)) |
| `file-pr` | "abrí el PR" | Abre un PR con título y descripción concisos, sin secretos. | Adaptada de `file-pr` ([tstack](https://github.com/t3dotgg/tstack)) |
| `babysit-pr` | "vigilá el PR" | Vigila CI y reviews del PR hasta que esté listo para mergear. Incluye `pr-wait`. | Adaptada de `babysit-pr` ([tstack](https://github.com/t3dotgg/tstack)) |
| `council` | "council" | Convoca a Opus, Gemini Argon y un tercer modelo a elección para revisar o dar feedback. | Adaptada de `council` ([tstack](https://github.com/t3dotgg/tstack)) |
| `full-send` | "full send" | Lleva el cambio solo hasta un PR mergeado: prueba, code-review, gemini-loop, PR y vigilancia. | Adaptada de `full-send` ([tstack](https://github.com/t3dotgg/tstack)) |
| `full-stop` | "full stop" | Igual que `full-send`, pero deja el PR listo sin mergear. | Adaptada de `full-stop` ([tstack](https://github.com/t3dotgg/tstack)) |
| `opsx-orchestrator` | "opsx" | Modo orquestador OpenSpec (propose/apply/archive), opt-in para proyectos que usan `openspec/`. | Propia (antes vivía en el `CLAUDE.md` global) |
| `leaving-pr-comments` | (automática) | Formatea los comentarios que un agente deja en GitHub en tu nombre. La usan `file-pr` y `babysit-pr`. | Adaptada de `leaving-pr-comments` ([tstack](https://github.com/t3dotgg/tstack)) |

## Workflow

El modo de trabajo de Matt Pocock con agregados. Los pasos con `/` los
escribís vos (esas skills no las puede invocar un agente); el resto lo encadena
el agente. Tracker en GitHub Issues: un PR por ticket.

```
/mattpocock-skills:grill-with-docs ─┬─ (trabado / dudas de diseño) ──→ council          [divergente]
                  ▼
/mattpocock-skills:to-spec        → issue de spec
                  ▼
/mattpocock-skills:to-tickets     → issues hijos con bloqueos
                  ▼
por ticket desbloqueado (rama <tipo>/<N>-<slug>):
  /mattpocock-skills:implement #N  (tdd + code-review) ── (mismo error 2 veces) ──→ advisor  [causa raíz]
                  ▼
  verify-<proyecto>                                                  [¿funciona de verdad?]
                  ▼
  gate final según governance                                        [convergente]
                  ▼
  file-pr (Closes #N) → babysit-pr   ← full-stop / full-send encadenan desde verify
```

Cada proyecto necesita antes `/mattpocock-skills:setup-matt-pocock-skills` con
GitHub como tracker.

Gate final según el nivel de governance del cambio (detalle en `config/CLAUDE.md`):

| Nivel | Revisión |
|---|---|
| LOW | Tests en verde |
| MEDIUM | `code-review` (Matt) |
| HIGH | `code-review` + `gemini-loop` |
| CRITICAL | `code-review` + `gemini-loop` + `council` |

Fundación (solo proyectos grandes): `discovery-research` → `kb-creator` →
`roadmap-generator` → `agent-instruction`.

## Instalación

Clonar el repo y copiar (o enlazar) las skills a la carpeta de skills del agente:

```powershell
git clone https://github.com/MatiasLimina/mstack
Copy-Item -Recurse -Force "mstack\skills\*" "$env:USERPROFILE\.claude\skills\"
Copy-Item -Force "$env:USERPROFILE\.claude\CLAUDE.md" "$env:USERPROFILE\.claude\CLAUDE.md.bak"  # backup del global actual
Copy-Item -Force "mstack\config\CLAUDE.md" "$env:USERPROFILE\.claude\CLAUDE.md"
```

### Dependencias

El workflow usa skills de terceros que este repo no copia:

```powershell
# Matt Pocock (grill-with-docs, to-spec, implement, tdd, code-review): plugin, se actualiza solo
claude plugin marketplace add mattpocock/skills
claude plugin install mattpocock-skills@mattpocock --scope user

# pstack (Lauren Tan): solo las dos skills de verificación; el plugin entero suma ~40 skills que el workflow no usa
git clone https://github.com/cursor/plugins cursor-plugins
Copy-Item -Recurse -Force "cursor-plugins\pstack\skills\create-verification-skill" "$env:USERPROFILE\.claude\skills\"
Copy-Item -Recurse -Force "cursor-plugins\pstack\skills\maintain-verification-skill" "$env:USERPROFILE\.claude\skills\"
```

No mezcles el plugin de Matt con copias sueltas de sus skills en
`~/.claude/skills`: quedarían duplicadas.

Los agentes `advisor` y `scout`, y las skills de fundación (`discovery-research`,
`kb-creator`, `roadmap-generator`, `agent-instruction`, `active-orchestrator`)
vienen de **active-stack**. Instalalo antes, pero ojo: su install/update
reescribe el `CLAUDE.md` global con bloques `active-stack:sdd-*`; después de
correrlo, volvé a copiar `config/CLAUDE.md`.

`config/CLAUDE.md` es el `CLAUDE.md` global: shell, workflow, governance,
gate final y preferencias. Reemplaza al tuyo (el bloque de instalación hace
backup en `CLAUDE.md.bak`).

## Preferencias personales

Los modelos y presupuestos que pueden cambiar con el tiempo van en el
`CLAUDE.md` / `AGENTS.md`, no dentro de las skills, para poder actualizar las
skills sin perder la configuración. Cada skill documenta sus defaults.

## Licencia

[MIT](LICENSE). Las partes derivadas de terceros conservan su aviso en
[`NOTICE.md`](NOTICE.md).

## Créditos

Este stack se apoya en el trabajo de otros. Gracias a:

- **Theo Browne** — [tstack](https://github.com/t3dotgg/tstack) (MIT).
  `gemini-loop`, `file-pr`, `babysit-pr`, `council`, `full-send`,
  `full-stop` y `leaving-pr-comments` son adaptaciones de sus skills
  (`sol-loop` y las homónimas).
  Ver [`NOTICE.md`](NOTICE.md).
- **Matt Pocock** — [skills](https://github.com/mattpocock/skills) (MIT).
  El flujo `grill-with-docs` → `to-spec` → `implement` + `tdd` → `code-review`
  del workflow usa sus skills tal cual; este repo no copia su código.
- **Lauren Tan** — [pstack](https://github.com/cursor/plugins/tree/main/pstack) (MIT).
  La idea de una skill de verificación por proyecto (`create-verification-skill`)
  viene de ahí; este repo no copia su código.

Si alguna skill de este repo pasa a derivar de otro trabajo, su licencia y
autoría se agregan a `NOTICE.md` y al encabezado de la skill.
